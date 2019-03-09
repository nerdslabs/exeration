defmodule Exeration.Observer do
  defmacro __using__(_options) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  @anno (if :erlang.system_info(:otp_release) >= '19' do
           [generated: true]
         else
           [line: -1]
         end)

  defmacro __before_compile__(env) do
    quote @anno do
      use GenServer

      def __is_observer__(), do: true

      def init(_), do: {:ok, []}

      def start_link(name \\ nil) do
        GenServer.start_link(unquote(env.module), nil, name: unquote(env.module))
      end

      def handle_cast({source, result}, state) do
        handle(source, result)
        {:noreply, result, :hibernate}
      end

      def handle(_, _), do: :skip

      defoverridable handle: 2
    end
  end

  def cast(modules: module) when is_atom(module) do
    [module]
  end

  def cast(modules: modules) when is_list(modules) do
    modules
  end

  def cast(nil), do: []
  def cast(modules: nil), do: []
end
