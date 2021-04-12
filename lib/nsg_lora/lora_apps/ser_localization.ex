defmodule NsgLora.LoraApps.SerLocalization do
  use GenServer
  require NsgLora.LoraWan
  alias NsgLora.LoraWan
  require Logger

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    {:ok,
     %{
       mode: :localization,
       coord: [0, 0],
       rssi_measures: []
     }}
  end

  @impl true
  def handle_cast({:rxq, %{gateways: gateways}}, state) do
    IO.inspect(state)

    rssi_vec =
      gateways
      |> Enum.map(fn {mac, rxq} ->
        {Base.encode16(mac), LoraWan.rxq(rxq)[:rssi]}
      end)
      |> Enum.into(%{})
      |> IO.inspect()

    case state.mode do
      :collect ->
        {:noreply, %{state | rssi_measures: [rssi_vec | state.rssi_measures]}}

      :localization ->
        {:noreply, state}
    end
  end

  def handle_cast({:set_mode, mode}, %{mode: :collect} = state) do
    collect_rssi_vec(state)
    {:noreply, %{state | mode: mode, rssi_measures: []}}
  end

  def handle_cast({:set_mode, mode}, state) do
    {:noreply, %{state | mode: mode}}
  end

  def handle_cast({:set_fp, coord}, state) do
    collect_rssi_vec(state)
    {:noreply, %{state | coord: coord, rssi_measures: []}}
  end

  defp collect_rssi_vec(%{coord: coord, rssi_measures: [_ | _] = vec}) do
    rssi =
      vec
      |> Enum.reduce(%{}, fn rssi, acc ->
        rssi
        |> Enum.reduce(acc, fn {mac, rssi}, acc ->
          {sum, n} = acc[mac] || {0, 0}
          Map.put(acc, mac, {sum + rssi, n + 1})
        end)
      end)
      |> Enum.map(fn {mac, {sum, n}} -> {mac, sum / n} end)

    NsgLora.Repo.Localization.write(%{coord: coord, rssi: rssi})
    |> IO.inspect()
  end

  defp collect_rssi_vec(_) do
  end

  def rxq(params) do
    GenServer.cast(__MODULE__, {:rxq, params})
  end

  def set_mode(mode) do
    GenServer.cast(__MODULE__, {:set_mode, mode})
  end
  def set_fp([_x, _y] = coord) do
    GenServer.cast(__MODULE__, {:set_fp, coord})
  end
end
