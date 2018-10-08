defmodule Exeration.Operation.Parameter do
  defmodule Invalid do
    defexception message: "Parameter is not in valid format"
  end

  alias Exeration.Operation.Parameter

  @type t :: %Exeration.Operation.Parameter{
          argument: atom(),
          type: atom(),
          required: boolean() | nil,
          struct: struct() | nil
        }

  @enforce_keys [:argument, :type, :required]
  defstruct [:argument, :type, :required, :struct]

  @allowed_types [
    :boolean,
    :integer,
    :float,
    :string,
    :tuple,
    :map,
    :struct,
    :list,
    :atom,
    :function,
    :dont_check
  ]

  @doc false
  def cast(params) when is_list(params) do
    Enum.into(params, %{}) |> cast()
  end

  @spec cast(%{
          argument: atom(),
          type:
            :atom
            | :boolean
            | :dont_check
            | :float
            | :function
            | :integer
            | :list
            | :map
            | :string
            | :struct
            | :tuple
        }) :: Exeration.Operation.Parameter.t()
  def cast(%{argument: argument, type: :struct, struct: struct, required: required})
      when is_atom(argument) and is_atom(struct) and is_boolean(required) do
    %Parameter{argument: argument, type: :struct, struct: struct, required: required}
  end

  def cast(%{argument: argument, type: :struct, struct: struct})
      when is_atom(argument) and is_atom(struct) and not is_nil(struct) do
    %Parameter{argument: argument, type: :struct, struct: struct, required: false}
  end

  def cast(%{argument: argument, type: :struct})
      when is_atom(argument) do
    raise Invalid, message: "Type `:struct` require struct argument with module as value"
  end

  def cast(%{argument: argument, type: type, required: required})
      when is_atom(argument) and type in @allowed_types and is_boolean(required) do
    %Parameter{argument: argument, type: type, required: required}
  end

  def cast(%{argument: argument, type: type})
      when is_atom(argument) and type in @allowed_types do
    %Parameter{argument: argument, type: type, required: false}
  end

  def cast(%{type: type}) when type not in allowed_types() do
    raise Invalid,
      message:
        "Type `#{type}` in not allowed type, allowed types: #{Enum.join(allowed_types(), ", ")}"
  end

  def cast(_) do
    raise Invalid
  end
end
