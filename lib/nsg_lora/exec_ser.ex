defmodule NsgLora.ExecSer do
  use GenServer, restart: :temporary
  require Logger

  def start_link(params = %{name: name}) do
    GenServer.start_link(__MODULE__, params, name: name)
  end

  @impl true
  def init(params = %{name: name, path: path}) do
    args = params[:args] || []

    port =
      Port.open({:spawn_executable, Application.app_dir(:nsg_lora) <> "/priv/share/wrapper.sh"}, [
        :binary,
        args: [path | args]
      ])

    port =
      case port do
        port when is_port(port) ->
          Port.monitor(port)

          Phoenix.PubSub.broadcast(
            NsgLora.PubSub,
            "exec_ser",
            {:change_port_status, name}
          )

          port

        _ ->
          nil
      end

    {:ok, %{name: name, port: port, data: CircularBuffer.new(100)}}
  end

  @impl true
  def handle_info({_port, {:data, data}}, state = %{name: name}) do
    Phoenix.PubSub.broadcast(
      NsgLora.PubSub,
      "exec_ser",
      {:get_data, name}
    )
    IO.inspect({data, String.length(data)}, label: "Port data")
    {:noreply, %{state | data: CircularBuffer.insert(state.data, data)}}
  end

  def handle_info({:DOWN, _ref, :port, port, _}, state = %{name: name, port: port}) do
    Phoenix.PubSub.broadcast(
      NsgLora.PubSub,
      "exec_ser",
      {:change_port_status, name}
    )

    {:noreply, %{state | port: nil}}
  end

  def handle_info(msg, state) do
    Logger.warn("ExecSer: unknown message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_data, _from, state) do
    {:reply, CircularBuffer.to_list(state.data), state}
  end

  def handle_call(:port_info, _from, state) do
    {:reply, Port.info(state.port), state}
  end

  def handle_call(:alive, _from, state) do
    res =
      case state.port do
        port when is_port(port) -> true
        _ -> false
      end

    {:reply, res, state}
  end

  @impl true
  def handle_cast(:port_close, state) do
    Port.close(state.port)
    {:noreply, state}
  end

  def handle_cast(:exit, state) do
    {:stop, :shutdown, state}
  end

  def start_child(params) do
    DynamicSupervisor.start_child(
      NsgLora.DynSup,
      child_spec(params)
    )
  end

  def get_data(name) do
    case pid(name) do
      pid when is_pid(pid) -> GenServer.call(pid, :get_data)
      _ -> ""
    end
  end

  def port_info(name) do
    GenServer.call(name, :port_info)
  end

  def port_close(name) do
    GenServer.cast(name, :port_close)
  end

  def exit(name) do
    GenServer.cast(name, :exit)
  end

  def pid(name) do
    Process.whereis(name)
  end

  def port_alive?(name) do
    case pid(name) do
      pid when is_pid(pid) -> GenServer.call(pid, :alive)
      _ -> false
    end
  end
end
