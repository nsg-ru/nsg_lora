defmodule NsgLora.LoraApps.SerRak7200 do
  use GenServer
  require NsgLora.LoraWan

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    {:ok,
     %{
       bs_position: %{lat: 55.777594, lon: 37.737926},
       markers: CircularBuffer.new(1024)
     }}
  end

  @impl true
  def handle_cast({:rxq, %{frame: frame, gateways: [{_mak, rxq} | _]}}, state) do
    data = NsgLora.LoraWan.frame(frame)[:data]

    data =
      try do
        :lorawan_application_backend.cayenne_decode(data)
      rescue
        _ -> nil
      end

    case data do
      %{"field1" => %{lat: lat, lon: lon}} ->
        rxq = NsgLora.LoraWan.rxq(rxq)

        marker = %{
          date: NaiveDateTime.local_now(),
          freq: rxq[:freq],
          rssi: rxq[:rssi],
          lsnr: rxq[:lsnr],
          lat: lat,
          lon: lon
        }

        Phoenix.PubSub.broadcast(
          NsgLora.PubSub,
          "nsg-rak7200",
          {:new_marker, marker}
        )

        {:noreply, %{state | markers: CircularBuffer.insert(state.markers, marker)}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:set_bs_position, position}, state) do
    {:noreply, %{state | bs_position: position}}
  end

  @impl true
  def handle_call(:get_bs_position, _from, state) do
    {:reply, state.bs_position, state}
  end

  def handle_call(:get_markers, _from, state) do
    {:reply, CircularBuffer.to_list(state.markers), state}
  end

  def handle_call({:get_markers, n}, _from, state) do
    {:reply, CircularBuffer.to_list(state.markers) |> Enum.take(n), state}
  end

  def rxq(params) do
    GenServer.cast(__MODULE__, {:rxq, params})
  end

  def get_bs_position() do
    GenServer.call(__MODULE__, :get_bs_position)
  end

  def set_bs_position(position) do
    GenServer.cast(__MODULE__, {:set_bs_position, position})
  end

  def get_markers() do
    GenServer.call(__MODULE__, :get_markers)
  end

  def get_markers(n) do
    GenServer.call(__MODULE__, {:get_markers, n})
  end
end
