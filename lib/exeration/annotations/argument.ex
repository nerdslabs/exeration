defmodule Exeration.Operation.Argument do
  defmodule Invalid do
    defexception message: "Argument is not in valid format"
  end

  alias Exeration.Operation.Argument

  @type t :: %Exeration.Operation.Argument{
          name: atom(),
          type: atom(),
          required: boolean() | nil,
          struct: struct() | nil
        }

  @enforce_keys [:name, :type, :required]
  defstruct [:name, :type, :required, :struct]

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

  defmacrop allowed_types do
    Application.get_env(:exeration, :custom_validators, [])
    |> Keyword.keys()
    |> Enum.concat(@allowed_types)
  end

  @doc false
  def cast(params) when is_list(params) do
    Enum.into(params, %{}) |> cast()
  end

  @spec cast(%{
          name: atom(),
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
        }) :: Exeration.Operation.Argument.t()
  def cast(%{name: name, type: :struct, struct: struct, required: required})
      when is_atom(name) and is_atom(struct) and is_boolean(required) do
    %Argument{name: name, type: :struct, struct: struct, required: required}
  end

  def cast(%{name: name, type: :struct, struct: struct})
      when is_atom(name) and is_atom(struct) and not is_nil(struct) do
    %Argument{name: name, type: :struct, struct: struct, required: false}
  end

  def cast(%{name: name, type: :struct})
      when is_atom(name) do
    raise Invalid, message: "Type `:struct` require struct name with module as value"
  end

  def cast(%{name: name, type: type, required: required})
      when is_atom(name) and type in allowed_types() and is_boolean(required) do
    %Argument{name: name, type: type, required: required}
  end

  def cast(%{name: name, type: type})
      when is_atom(name) and type in allowed_types() do
    %Argument{name: name, type: type, required: false}
  end

  def cast(%{type: type}) when type not in allowed_types() do
    raise Invalid,
      message:
        "Type `#{type}` in not allowed type or not registred custom type, allowed types: #{
          Enum.join(allowed_types(), ", ")
        }"
  end

  def cast(%{name: name}) do
    raise Invalid, message: "Argument #{name} is not in valid format"
  end

  def cast(_) do
    raise Invalid
  end
end
