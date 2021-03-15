defmodule NsgLora.LagerRing do
  use GenServer

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end



  @impl true
  def init(_params) do
    {:ok, %{log: CircularBuffer.new(1024)}}
  end

  @impl true
  def handle_cast({:log, msg}, state) do
    {:noreply, %{state | log: CircularBuffer.insert(state.log, msg)}}
  end

  @impl true
  def handle_call(:get_log, _from, state) do
    {:reply, CircularBuffer.to_list(state.log), state}
  end

  def log(msg) do
    GenServer.cast(__MODULE__, {:log, msg})
  end

  def get_log() do
    GenServer.call(__MODULE__, :get_log)
  end
end
