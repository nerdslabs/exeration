defmodule Exeration.Validation do
  alias Exeration.Operation.Parameter

  def check([%Parameter{} = parameter | parameters], arguments) do
    value = Keyword.get(arguments, parameter.argument)

    with {:required, true} <- check_required(parameter, value),
        {:type, true} <- check_type(parameter, value) do
      check(parameters, arguments)
    else
      {:type, false} -> {:validate, false, :type, parameter}
      {:required, false} -> {:validate, false, :required, parameter}
    end
  end

  def check([], _) do
    {:validate, true}
  end

  defp check_required(%Parameter{required: true}, value) do
    case not is_nil(value) do
      true -> {:required, true}
      false -> {:required, false}
    end
  end

  defp check_required(%Parameter{required: false}, _) do
    {:required, true}
  end

  defp check_type(%Parameter{type: :boolean}, value) do
    case is_boolean(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :integer}, value) do
    case is_integer(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :float}, value) do
    case is_float(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :string}, value) do
    case is_binary(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :tuple}, value) do
    case is_tuple(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :map}, value) do
    case is_map(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :struct} = parameter, value) do
    case is_map(value) && is_struct(value) && value.__struct__ == parameter.struct do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :list}, value) do
    case is_list(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :atom}, value) do
    case is_atom(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :function}, value) do
    case is_function(value) do
      true -> {:type, true}
      false -> {:type, false}
    end
  end

  defp check_type(%Parameter{type: :dont_check}, _) do
    {:type, true}
  end

  defp is_struct(%{__struct__: _} = item) when is_map(item), do: true
  defp is_struct(_), do: false
end
