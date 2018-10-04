defmodule Exeration.Operation.Authorize do
  defmodule InvalidAuthorize do
    defexception message: "Authorize is not in valid format"
  end

  alias Exeration.Operation.Authorize

  @type t :: %Exeration.Operation.Authorize{
          policy: fun(),
          arguments: list(atom()) | nil
        }

  @enforce_keys [:policy]
  defstruct [:policy, :arguments]

  @doc false
  def cast(params) when is_list(params) do
    Enum.into(params, %{}) |> cast()
  end

  @doc false
  def cast(params) when is_nil(params) do
    nil
  end

  def cast(%{policy: policy, arguments: arguments})
      when not is_nil(policy) and is_function(policy) and is_list(arguments) do
    %Authorize{policy: policy, arguments: arguments}
  end

  def cast(%{policy: policy})
      when not is_nil(policy) and is_function(policy) do
    %Authorize{policy: policy}
  end

  def cast(_) do
    raise InvalidAuthorize
  end
end
