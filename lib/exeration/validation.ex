defmodule Exeration.Validation do
  alias Exeration.Operation.Argument

  def check([%Argument{name: name, type: type} = argument | arguments], function_arguments) do
    value = Keyword.get(function_arguments, name)

    with :ok <- check_required(argument, value),
         :ok <- check_type(argument, value) do
      check(arguments, function_arguments)
    else
      :error -> {:error, name, type}
    end
  end

  def check([], _) do
    {:ok, :validation}
  end

  defp check_required(%Argument{required: true}, value) do
    case not is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_required(%Argument{required: false}, _) do
    :ok
  end

  defp check_type(%Argument{type: :boolean}, value) do
    case is_boolean(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :integer}, value) do
    case is_integer(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :float}, value) do
    case is_float(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :string}, value) do
    case is_binary(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :tuple}, value) do
    case is_tuple(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :map}, value) do
    case is_map(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :struct} = argument, value) do
    case (is_map(value) and map_is_struct(value) and value.__struct__ == argument.struct) or
           is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :list}, value) do
    case is_list(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :atom}, value) do
    case is_atom(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :function}, value) do
    case is_function(value) or is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Argument{type: :dont_check}, _) do
    :ok
  end

  defp check_type(%Argument{type: custom} = argument, value) do
    Application.fetch_env!(:exeration, :custom_validators)
    |> Keyword.get(custom, nil)
    |> case do
      nil ->
        raise Exeration.Validator.Error,
          message: "Custom validator '#{custom}' not presented in config"

      module ->
        Kernel.apply(module, :check, [argument, value])
    end
    |> case do
      :ok ->
        :ok

      :error ->
        :error

      _ ->
        raise Exeration.Validator.Error,
          message: "Custom validator '#{custom}' should return ':ok' or ':error'"
    end
  end

  defp map_is_struct(%{__struct__: _} = item) when is_map(item), do: true
  defp map_is_struct(_), do: false
end
