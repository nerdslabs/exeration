defmodule Exeration.Operation do
  defmodule MissingArgument do
    defexception message: "Parameter not exists as argument in function"
  end

  defmodule MissingParameter do
    defexception message: "Argument don't have parameter description"
  end

  defmacro __using__(options) do
    quote do
      Module.put_attribute(__MODULE__, :observers, Keyword.get(unquote(options), :observers, []))

      Module.register_attribute(__MODULE__, :authorize, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :parameter, accumulate: true, persist: false)
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

  alias Exeration.Operation.Parameter
  alias Exeration.Operation.Authorize
  alias Exeration.Observer.Supervisor
  alias Exeration.Observer

  def __on_definition__(env, kind, name, args, guards, body) do
    parameters =
      Module.get_attribute(env.module, :parameter)
      |> Enum.map(&Parameter.cast/1)

    authorize =
      Module.get_attribute(env.module, :authorize)
      |> Authorize.cast()

    observers = Module.get_attribute(env.module, :observe)
      |> Observer.cast()

    bind_operation(env, kind, name, args, guards, body, parameters, authorize, observers)

    Module.delete_attribute(env.module, :parameter)
    Module.delete_attribute(env.module, :authorize)
    Module.delete_attribute(env.module, :observe)
  end

  defp bind_operation(_, _, _, _, _, _, [], nil, _), do: :not_operation

  defp bind_operation(env, _kind, name, args_quote, guards, [do: body], parameters, authorize, observers) do
    args = Enum.reduce(args_quote, [], fn
      ({:=, _, [_ | [{argument, _, _} | _]]}, acc) -> [argument | acc]
      ({argument, _, _}, acc) -> [argument | acc]
      (_, acc) -> [:_filled | acc]
    end) |> Enum.reverse

    check_parameters_arguments(env.module, name, length(args_quote), args, parameters)

    operation =
      create_quote(env.module, name, args, args_quote, guards, body, parameters, authorize, observers)

    Module.put_attribute(env.module, :methods, {name, length(args_quote), operation})
  end

  defp check_parameters_arguments(module, name, arity, arguments, parameters) do
    parameters = Enum.map(parameters, &Map.get(&1, :argument))

    Enum.each(parameters, fn parameter ->
      unless Enum.member?(arguments, parameter) do
        raise MissingArgument,
          message:
            "Parameter '#{parameter}' not exists as argument in function '#{module}.#{name}/#{
              arity
            }'"
      end
    end)

    Enum.each(arguments, fn
      :_filled -> :_filled
      argument ->
        unless Enum.member?(parameters, argument) do
          raise MissingParameter,
            message:
              "Argument '#{argument}' don't have parameter description in function '#{module}.#{
                name
              }/#{arity}'"
        end
    end)
  end

  defp create_quote(_module, name, args, args_quote, guards, body, parameters, authorize, observers) do
    guard = get_guard(guards)
    parameters = Macro.escape(parameters)
    authorize = Macro.escape(authorize)

    quote @anno do
      def unquote(name)(unquote_splicing(args_quote)) when unquote(guard) do
        arguments = Enum.zip(unquote(args), [unquote_splicing(args_quote)])

        result = with {:ok, :validation} <- Exeration.Validation.check(unquote(parameters), arguments),
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
