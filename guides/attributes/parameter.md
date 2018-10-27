# Parameter

## Basic usage
```elixir
@parameter argument: :id, type: :integer
```

## Built validators 
List of validators built into the library `[:boolean, :integer, :float, :string, :tuple, :map, :struct, :list, :atom, :function, :dont_check]`,
if you want to add own validator you can do it, check more info here.

## Options
List of options that you can pass to `@parameter`.

### Struct
```elixir
@parameter argument: :user, type: :struct, struct: Example.User
```

## Results

**Success**
```elixir
{:ok, result} = Examole.set(user, file_id, file_content)
```
**Error**
```elixir
{:error, parameter, required_type} = Examole.set(user, file_id, file_content)
{:error, :file_id, :integer} = Examole.set(user, file_id, file_content)
```