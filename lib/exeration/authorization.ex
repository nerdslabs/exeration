defmodule Exeration.Authorization do
  alias Exeration.Operation.Authorize

  def check(%Authorize{policy: policy, arguments: arguments}, args)
      when is_list(arguments) do
    arguments = Enum.map(arguments, &Keyword.get(args, &1))

    case Kernel.apply(policy, arguments) do
      true -> {:authorize, true}
      false -> {:authorize, false}
    end
  end

  def check(%Authorize{policy: policy}, args) do
    arguments = Keyword.values(args)

    case Kernel.apply(policy, arguments) do
      true -> {:authorize, true}
      false -> {:authorize, false}
    end
  end

  def check(_, _), do: {:authorize, true}
end
