defmodule ExerationTest do
  use ExUnit.Case
  doctest Exeration

  defmodule Example do
    use Exeration.Operation, observers: [ExerationTest.Observer]

    defmodule Struct do
      defstruct [:name, :is_folder]
    end

    @argument name: :user, type: :string
    @argument name: :file, type: :string, required: true
    def test(user, file) when is_binary(user) do
      {:ok, {user, file}}
    end

    @argument name: :file, type: :struct, struct: Struct
    @authorize policy: &ExerationTest.Example.auth?/1, arguments: [:file]
    def get(file), do: {:ok, file}

    @argument name: :default, type: :string
    def default(default \\ "abc"), do: {:ok, default}

    @authorize policy: &ExerationTest.Example.auth?/0
    def list(), do: {:ok, ["a", "b"]}

    @argument name: :string, type: :test
    def validator(string), do: {:ok, string}

    @argument name: :atom, type: :atom
    @observe modules: ExerationTest.Observer
    def observe(atom), do: {:ok, atom}

    def auth?(file) do
      file.is_folder
    end

    def auth?() do
      true
    end
  end

  defmodule Validator do
    @behaviour Exeration.Validator

    def check(_argument, value) do
      case String.length(value) do
        1 -> :ok
        _ -> :error
      end
    end
  end

  defmodule Observer do
    use Exeration.Observer

    def handle({_name, _arity}, _result) do
    end
  end

  test "test non nil" do
    assert {:ok, {"main", "test.txt"}} == ExerationTest.Example.test("main", "test.txt")
  end

  test "test nil" do
    assert {:error, :file, :string} == ExerationTest.Example.test("main", nil)
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
    assert {:error, :file, :struct} ==
             ExerationTest.Example.get(%{name: "text.txt", is_folder: true})
  end

  test "test detault" do
    assert {:ok, "abc"} == ExerationTest.Example.default()
  end

  test "list authenticated" do
    assert {:ok, ["a", "b"]} == ExerationTest.Example.list()
  end

  test "custom validator positive" do
    assert {:ok, "a"} == ExerationTest.Example.validator("a")
  end

  test "custom validator negative" do
    assert {:error, :string, :test} == ExerationTest.Example.validator("ab")
  end

  test "observer" do
    ExerationTest.Example.observe(:observe)

    pid = GenServer.whereis(ExerationTest.Observer)

    assert {:ok, :observe} == :sys.get_state(pid)
  end
end
