defmodule Exeration.Operation do
  defmodule MissingArgument do
    defexception message: "Argument not exists in function"
  end

  defmodule MissingDescription do
    defexception message: "Argument don't have description"
  end

  defmacro __using__(options) do
    quote do
      Module.put_attribute(__MODULE__, :observers, Keyword.get(unquote(options), :observers, []))

      Module.register_attribute(__MODULE__, :authorize, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :argument, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :methods, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :observe, accumulate: false, persist: false)

      @on_definition unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  @anno (if :erlang.system_info(:otp_release) >= '19' do
           [generated: true]
         else
           [line: -1]
         end)

  defmacro __before_compile__(env) do
    methods = Module.get_attribute(env.module, :methods)

    overridables = for {name, arity, _function_quote} <- methods do
      quote @anno do
        if Module.overridable?(unquote(env.module), {unquote(name), unquote(arity)}) == false do
          defoverridable Keyword.new([{unquote(name), unquote(arity)}])
        end
      end
    end

    functions = for {_name, _arity, function_quote} <- methods do
      quote @anno do
        Module.eval_quoted(unquote(env.module), unquote(function_quote))
      end
    end

    Enum.concat(overridables, functions)
  end

  alias Exeration.Operation.Argument
  alias Exeration.Operation.Authorize
  alias Exeration.Observer.Supervisor
  alias Exeration.Observer

  def __on_definition__(env, kind, name, args_quote, guards, body) do
    arguments =
      Module.get_attribute(env.module, :argument)
      |> Enum.map(&Argument.cast/1)

    authorize =
      Module.get_attribute(env.module, :authorize)
      |> Authorize.cast()

    observers = Module.get_attribute(env.module, :observe)
      |> Observer.cast()

    bind_operation(env, kind, name, args_quote, guards, body, arguments, authorize, observers)

    Module.delete_attribute(env.module, :argument)
    Module.delete_attribute(env.module, :authorize)
    Module.delete_attribute(env.module, :observe)
  end

  defp bind_operation(_, _, _, _, _, _, [], nil, _), do: :not_operation

  defp bind_operation(env, _kind, name, args_quote, guards, [do: body], arguments, authorize, observers) do
    args = Enum.reduce(args_quote, [], fn
      ({:=, _, [_ | [{argument, _, _} | _]]}, acc) -> [argument | acc]
      ({:\\, _, [{argument, _, _}, _]}, acc) -> [argument | acc]
      ({argument, _, _}, acc) -> [argument | acc]
      (_, acc) -> [:_filled | acc]
    end) |> Enum.reverse

    check_arguments_arguments(env.module, name, length(args_quote), args, arguments)

    operation =
      create_quote(env.module, name, args, args_quote, guards, body, arguments, authorize, observers)

    Module.put_attribute(env.module, :methods, {name, length(args_quote), operation})
  end

  defp check_arguments_arguments(module, name, arity, args, arguments) do
    arguments = Enum.map(arguments, &Map.get(&1, :name))

    Enum.each(arguments, fn argument ->
      unless Enum.member?(args, argument) do
        raise MissingArgument,
          message:
            "Argument '#{argument}' not exists in function '#{module}.#{name}/#{
              arity
            }'"
      end
    end)

    Enum.each(args, fn
      :_filled -> :_filled
      argument ->
        unless Enum.member?(arguments, argument) do
          raise MissingDescription,
            message:
              "Argument '#{argument}' don't have description in function '#{module}.#{
                name
              }/#{arity}'"
        end
    end)
  end

  defp create_quote(_module, name, args, args_quote, guards, body, arguments, authorize, observers) do
    guard = get_guard(guards)
    arguments = Macro.escape(arguments)
    authorize = Macro.escape(authorize)

    args_bindings = Enum.map(args, fn arg -> {arg, [], nil} end)

    quote @anno do
      def unquote(name)(unquote_splicing(args_quote)) when unquote(guard) do
        arguments = Enum.zip(unquote(args), [unquote_splicing(args_bindings)])

        result = with {:ok, :validation} <- Exeration.Validation.check(unquote(arguments), arguments),
            {:ok, :authorize} <- Exeration.Authorization.check(unquote(authorize), arguments) do
          unquote(body)
        else
          {:error, argument, type} -> {:error, argument, type}
          {:error, :authorize} -> {:error, :not_authorized}
        end

        Supervisor.notify_observers(unquote(observers), unquote(name), unquote(length(args)), result)

        result
      end
    end
  end

  defp get_guard([guard | _]), do: guard
  defp get_guard(_), do: true
end
