defmodule Exeration.Validator do
  @callback check(Exeration.Operation.Parameter.t(), any()) :: :ok | :error

  defmodule Error do
    defexception message: "Custom validator not presented in config"
  end
end
