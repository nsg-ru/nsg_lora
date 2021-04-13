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

    case state.mode do
      :collect ->
        rssi_measures = [rssi_vec | state.rssi_measures]

        Phoenix.PubSub.broadcast(
          NsgLora.PubSub,
          "nsg-localization",
          {:rssi_measures, rssi_measures}
        )

        {:noreply, %{state | rssi_measures: rssi_measures}}

      :localization ->
        IO.inspect(rssi_vec, label: "Localization")
        {:ok, fp_matrix} = NsgLora.Repo.Localization.all()

        {sy, sx, sw} =
          fp_matrix
          |> Enum.map(fn %{coord: coord, rssi: rssi_fp} ->
            {coord, distance(rssi_vec, rssi_fp)}
          end)
          |> Enum.sort_by(fn {_, d} -> d end)
          |> Enum.take(4)
          |> Enum.reduce({0, 0, 0}, fn {[y, x], d}, {sy, sx, sw} ->
            w = 1 / d
            {sy + y * w, sx + x * w, sw + w}
          end)

        point = [sy / sw, sx / sw]

        Phoenix.PubSub.broadcast(
          NsgLora.PubSub,
          "nsg-localization",
          {:new_marker, point}
        )

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

  @impl true
  def handle_call(:get_mode, _from, state) do
    {:reply, state.mode, state}
  end

  def handle_call(:get_coord, _from, state) do
    {:reply, state.coord, state}
  end

  def handle_call(:get_rssi_measures, _from, state) do
    {:reply, state.rssi_measures, state}
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

    Phoenix.PubSub.broadcast(
      NsgLora.PubSub,
      "nsg-localization",
      {:new_fp, coord}
    )
  end

  defp collect_rssi_vec(_) do
  end

  defp distance(map, list) do
    list
    |> Enum.map(fn {mac, rssi} ->
      case map[mac] do
        nil -> nil
        v -> :math.pow(rssi - v, 2)
      end
    end)
    |> Enum.filter(fn x -> x end)
    |> IO.inspect()
    |> Enum.sum()
    |> :math.sqrt()
  end

  def rxq(params) do
    GenServer.cast(__MODULE__, {:rxq, params})
  end

  def set_mode(mode) do
    GenServer.cast(__MODULE__, {:set_mode, mode})
  end

  def set_fp([_y, _x] = coord) do
    GenServer.cast(__MODULE__, {:set_fp, coord})
  end

  def get_mode() do
    GenServer.call(__MODULE__, :get_mode)
  end

  def get_fp() do
    GenServer.call(__MODULE__, :get_coord)
  end

  def get_rssi_measures() do
    GenServer.call(__MODULE__, :get_rssi_measures)
  end
end
