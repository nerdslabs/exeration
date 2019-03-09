defmodule Exeration.Observer.Supervisor do
  use DynamicSupervisor

  @observers :observers_registry

  def start_link() do
    :ets.new(@observers, [:named_table, :public])

    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(initial_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [initial_arg]
    )
  end

  def find_observers() do
    :application.loaded_applications()

    Enum.reduce(:application.loaded_applications(), [], fn {app, _, _}, acc ->
      {:ok, modules} = :application.get_key(app, :modules)

      Enum.reduce(modules, acc, fn module, acc ->
        Code.ensure_loaded(module)

        case :erlang.function_exported(module, :__is_observer__, 0) do
          false -> acc
          true -> [module | acc]
        end
      end)
    end)
  end

  def add_observer(module) do
    spec = %{id: module, start: {module, :start_link, []}}
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
    :ets.insert(@observers, {module, pid})
  end

  def notify_observers(modules, name, arity, data) do
    Enum.each(modules, fn module ->
      if :ets.lookup(@observers, module) == [] do
        Exeration.Observer.Supervisor.add_observer(module)
      end

      [{_, pid}] = :ets.lookup(@observers, module)
      GenServer.cast(pid, {{name, arity}, data})
    end)
  end
end
