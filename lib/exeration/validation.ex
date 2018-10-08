defmodule Exeration.Validation do
  alias Exeration.Operation.Parameter

  def check([%Parameter{argument: argument, type: type} = parameter | parameters], arguments) do
    value = Keyword.get(arguments, parameter.argument)

    with :ok <- check_required(parameter, value),
        :ok <- check_type(parameter, value) do
      check(parameters, arguments)
    else
      :error -> {:error, argument, type}
    end
  end

  def check([], _) do
    {:ok, :validation}
  end

  defp check_required(%Parameter{required: true}, value) do
    case not is_nil(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_required(%Parameter{required: false}, _) do
    :ok
  end

  defp check_type(%Parameter{type: :boolean}, value) do
    case is_boolean(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :integer}, value) do
    case is_integer(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :float}, value) do
    case is_float(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :string}, value) do
    case is_binary(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :tuple}, value) do
    case is_tuple(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :map}, value) do
    case is_map(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :struct} = parameter, value) do
    case is_map(value) && is_struct(value) && value.__struct__ == parameter.struct do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :list}, value) do
    case is_list(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :atom}, value) do
    case is_atom(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :function}, value) do
    case is_function(value) do
      true -> :ok
      false -> :error
    end
  end

  defp check_type(%Parameter{type: :dont_check}, _) do
    :ok
  end

  defp check_type(%Parameter{type: custom} = parameter, value) do
    Application.fetch_env!(:exeration, :custom_validators)
    |> Keyword.get(custom, nil)
    |> case do
      nil -> raise Exeration.Validator.Error, message: "Custom validator '#{custom}' not presented in config"
      module -> Kernel.apply(module, :check, [parameter, value])
    end
    |> case do
      :ok -> :ok
      :error -> :error
      _ -> raise Exeration.Validator.Error, message: "Custom validator '#{custom}' should return ':ok' or ':error'"
    end
  end

  defp is_struct(%{__struct__: _} = item) when is_map(item), do: true
  defp is_struct(_), do: false
end
