defmodule NsgLora.ExecSer do
  use GenServer, restart: :temporary
  require Logger

  def start_link(params = %{name: name}) do
    IO.inspect(params, label: "START")
    GenServer.start_link(__MODULE__, params, name: name)
  end

  @impl true
  def init(params = %{path: path}) do
    IO.inspect(params, label: "INIT")
    Process.flag(:trap_exit, true)

    args = params[:args] || []

    port =
      Port.open({:spawn_executable, Application.app_dir(:nsg_lora) <> "/priv/share/wrapper.sh"}, [
        :binary,
        args: [path | args]
      ])

    # Port.monitor(port)

    {:ok, %{port: port, data: CircularBuffer.new(10)}}
  end

  @impl true
  def handle_info({_port, {:data, data}}, state) do
    {:noreply, %{state | data: CircularBuffer.insert(state.data, data)}}
  end

  def handle_info(msg, state) do
    Logger.warn("ExecSer: unknown message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_data, _from, state) do
    {:reply, CircularBuffer.to_list(state.data), state}
  end

  @impl true
  def terminate(reason, state) do
    IO.inspect(reason)
    Port.close(state.port)
  end

  def start_child(params) do
    DynamicSupervisor.start_child(
      NsgLora.DynSup,
      child_spec(params)
    )
  end

  def get_data(name) do
    GenServer.call(name, :get_data)
  end
end
