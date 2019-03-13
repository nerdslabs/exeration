# Parameter

## Basic usage
```elixir
@parameter argument: :id, type: :integer
def get(id) do
  # Some logic
  {:ok, result}
end
```

## Built validators 
List of validators built into the library `[:boolean, :integer, :float, :string, :tuple, :map, :struct, :list, :atom, :function, :dont_check]`,
if you want to add own validator you can do it, check more info here.

## Options
List of options that you can pass to `@parameter`.

### Struct
```elixir
@parameter argument: :user, type: :struct, struct: Example.User
def get(user) do
  # Some logic
  {:ok, result}
end
```

## Results

**Success**
```elixir
{:ok, result} = Example.get(user)
```
**Error**
```elixir
{:error, parameter, required_type} = Example.get(user)
{:error, :file_id, :integer} = Example.get(user)
```