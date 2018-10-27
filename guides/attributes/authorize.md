# Authorize

## All arguments

Pass all arguments in same order to specified policy function
```elixir
  @authorize policy: &Example.auth?/1
  def list(page), do: ["a", "b"]
```

## Specified arguments

```elixir
  @authorize policy: &Example.auth?/2, arguments: [:user, :file_id]
  def set(user, file_id, file_content) do
    # Some logic
  end
```

## Results

**Success**
```elixir
{:ok, result} = Example.set(user, file_id, file_content)
```
**Error**
```elixir
{:error, :not_authorized} = Example.set(user, file_id, file_content)
```