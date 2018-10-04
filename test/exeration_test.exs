defmodule ExerationTest do
  use ExUnit.Case
  doctest Exeration

  defmodule Example do
    use Exeration.Operation

    defmodule Struct do
      defstruct [:name, :is_folder]
    end

    @parameter argument: :user, type: :string
    @parameter argument: :file, type: :string, required: true
    def test(user, file) when is_binary(user) do
      {user, file}
    end

    @parameter argument: :file, type: :struct, struct: Struct
    @authorize policy: &ExerationTest.Example.auth?/1, arguments: [:file]
    def get(file), do: file

    @authorize policy: &ExerationTest.Example.auth?/0
    def list(), do: ["a", "b"]

    def auth?(file) do
      file.is_folder
    end

    def auth?() do
      true
    end
  end

  test "test non nil" do
    assert {:ok, {"main", "test.txt"}} == ExerationTest.Example.test("main", "test.txt")
  end

  test "test nil" do
    assert {:error, :required_argument, :file} == ExerationTest.Example.test("main", nil)
  end

  test "get authenticated" do
    assert {:ok, %Example.Struct{name: "text.txt", is_folder: true}} ==
             ExerationTest.Example.get(%Example.Struct{name: "text.txt", is_folder: true})
  end

  test "get non authenticated" do
    assert {:error, :not_authorized} ==
             ExerationTest.Example.get(%Example.Struct{name: "text.txt", is_folder: false})
  end

  test "get non struct" do
    assert {:error, :invalid_argument, :file} ==
             ExerationTest.Example.get(%{name: "text.txt", is_folder: true})
  end

  test "list authenticated" do
    assert {:ok, ["a", "b"]} == ExerationTest.Example.list()
  end
end
