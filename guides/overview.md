# Getting started

## Installation
At first add `:exeration` to `mix.exs` file:
```elixir
  defp deps do
    [
      {:exeration, "~> 1.0.0"}
    ]
  end
```

## Basic usage
Add `use Exeration.Operation` to selected module, next use following attributes: 

* `@parameter` ([documentation](https://www.google.com)) 
* `@authorize` ([documentation](https://www.google.com))

```elixir
defmodule Example do
  use Exeration.Operation

  @parameter argument: :id, type: :integer
  def get_user(id) do
    # Some logic
    {:ok, user}
  end

  @authorize policy: &Example.auth?/0
  def list_users() do
    # Some logic
    {:ok, ["a", "b"]}
  end

  @parameter argument: :user, type: :struct, struct: Example.User
  @parameter argument: :id, type: :integer
  @authorize policy: &Example.auth?/2
  def delete_user(user, id) do
    # Some logic
    {:ok, ["a", "b"]}
  end

  def auth?() do
    true
  end

  def auth?(user, _id) do
    user.is_admin
  end

end
```

## Executing operations
You can run every operation in same way like always, for example in `iex`
```elixir
iex(1)> Example.get_user(1)
{:ok, %Example.User{
  # ...
}}
```
or in other module
```elixir
defmodule Example.PageController do

  def display_users(id) do
    {:ok, user} = Example.get_user(id)
    # Some logic
  end

end
```