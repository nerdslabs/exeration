defmodule Exeration.Operation do
  defmodule MissingArgument do
    defexception message: "Parameter not exists as argument in function"
  end

  defmodule MissingParameter do
    defexception message: "Argument don't have parameter description"
  end

  defmacro __using__(_options) do
    quote do
      Module.register_attribute(__MODULE__, :authorize, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :parameter, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :methods, accumulate: true, persist: false)

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

    for {name, arity, function_quote} <- methods do
      quote @anno do
        defoverridable Keyword.new([{unquote(name), unquote(arity)}])
        Module.eval_quoted(unquote(env.module), unquote(function_quote))
      end
    end
  end

  alias Exeration.Operation.Parameter
  alias Exeration.Operation.Authorize

  def __on_definition__(env, kind, name, args, guards, body) do
    parameters =
      Module.get_attribute(env.module, :parameter)
      |> Enum.map(&Parameter.cast/1)

    authorize =
      Module.get_attribute(env.module, :authorize)
      |> Authorize.cast()

    bind_operation(env, kind, name, args, guards, body, parameters, authorize)

    Module.delete_attribute(env.module, :parameter)
    Module.delete_attribute(env.module, :authorize)
  end

  defp bind_operation(_, _, _, _, _, _, [], nil), do: :not_operation

  defp bind_operation(env, _kind, name, args_quote, guards, [do: body], parameters, authorize) do
    args = Enum.map(args_quote, &elem(&1, 0))

    check_parameters_arguments(env.module, name, length(args), args, parameters)

    operation =
      create_quote(name, args, args_quote, guards, body, parameters, authorize)

    Module.put_attribute(env.module, :methods, {name, length(args), operation})
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

    Enum.each(arguments, fn argument ->
      unless Enum.member?(parameters, argument) do
        raise MissingParameter,
          message:
            "Argument '#{argument}' don't have parameter description in function '#{module}.#{
              name
            }/#{arity}'"
      end
    end)
  end

  defp create_quote(name, args, args_quote, guards, body, parameters, authorize) do
    guard = get_guard(guards)
    parameters = Macro.escape(parameters)
    authorize = Macro.escape(authorize)

    quote @anno do
      def unquote(name)(unquote_splicing(args_quote)) when unquote(guard) do
        arguments = Enum.zip(unquote(args), [unquote_splicing(args_quote)])

        with {:ok, :validation} <- Exeration.Validation.check(unquote(parameters), arguments),
            {:ok, :authorize} <- Exeration.Authorization.check(unquote(authorize), arguments) do
          {:ok, unquote(body)}
        else
          {:error, argument, type} -> {:error, argument, type}
          {:error, :authorize} -> {:error, :not_authorized}
        end
      end
    end
  end

  defp get_guard([guard | _]), do: guard
  defp get_guard(_), do: true
end
