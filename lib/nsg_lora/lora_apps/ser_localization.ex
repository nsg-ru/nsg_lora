defmodule NsgLora.LoraApps.SerLocalization do
  use GenServer
  require NsgLora.LoraWan
  alias NsgLora.LoraWan
  require Logger

  @k 4
  @g 2

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    {:ok,
     %{
       mode: :localization,
       coord: [0, 0],
       rssi_measures: %{}
     }}
  end

  @impl true
  def handle_cast({:rxq, %{gateways: gateways}}, state) do
    rssi_vec =
      gateways
      |> Enum.map(fn {mac, rxq} ->
        {Base.encode16(mac), LoraWan.rxq(rxq)[:rssi]}
      end)

    case state.mode do
      :collect ->
        rssi_measures =
          rssi_vec
          |> Enum.reduce(state.rssi_measures, fn {mac, rssi}, acc ->
            rssi_list = acc[mac] || []
            Map.put(acc, mac, [rssi | rssi_list])
          end)

        Phoenix.PubSub.broadcast(
          NsgLora.PubSub,
          "nsg-localization",
          {:rssi_measures, rssi_measures}
        )

        {:noreply, %{state | rssi_measures: rssi_measures}}

      :localization ->
        {:ok, fp_matrix} = NsgLora.Repo.Localization.all()

        {sy, sx, sw} =
          fp_matrix
          |> Enum.map(fn %{coord: coord, rssi: rssi_fp} ->
            {coord, distance(rssi_vec, rssi_fp)}
          end)
          |> Enum.sort_by(fn {_, d} -> d end)
          |> Enum.take(@k)
          |> Enum.reduce({0, 0, 0}, fn {[y, x], d}, {sy, sx, sw} ->
            w = 1 / :math.pow(d, @g)
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
    state = collect_rssi_vec(state) |> set_mode(mode)
    {:noreply, state}
  end

  def handle_cast({:set_mode, mode}, state) do
    {:noreply, set_mode(state, mode)}
  end

  def handle_cast({:set_fp, coord}, state) do
    Phoenix.PubSub.broadcast(
      NsgLora.PubSub,
      "nsg-localization",
      {:update_tp, coord}
    )

    state = collect_rssi_vec(state)
    {:noreply, %{state | coord: coord}}
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

  defp collect_rssi_vec(%{rssi_measures: vec} = state) when vec == %{} do
    state
  end

  defp collect_rssi_vec(%{coord: coord, rssi_measures: %{} = vec} = state) do
    rssi =
      vec
      |> Enum.map(fn {mac, rssi_list} -> {mac, avg(rssi_list, :med)} end)

    {:ok, fp} = NsgLora.Repo.Localization.write(%{coord: coord, rssi: rssi})

    Phoenix.PubSub.broadcast(
      NsgLora.PubSub,
      "nsg-localization",
      {:new_fp, fp}
    )

    %{state | rssi_measures: %{}}
  end

  # defp avg(rssi_list, :avg) do
  #   Enum.sum(rssi_list) / length(rssi_list)
  # end

  defp avg(rssi_list, :med) do
    l = length(rssi_list)

    case rem(l, 2) do
      0 -> (Enum.at(rssi_list, div(l, 2)) + Enum.at(rssi_list, div(l, 2) - 1)) / 2
      1 -> Enum.at(rssi_list, div(l, 2))
    end
  end

  defp distance(tp, list) do
    map = Map.new(tp)

    list
    |> Enum.map(fn {mac, rssi} ->
      case map[mac] do
        nil -> nil
        v -> :math.pow(rssi - v, 2)
      end
    end)
    |> Enum.filter(fn x -> x end)
    |> Enum.sum()
    |> :math.sqrt()
  end

  defp set_mode(state, mode) do
    Phoenix.PubSub.broadcast(
      NsgLora.PubSub,
      "nsg-localization",
      {:training, mode == :collect}
    )

    %{state | mode: mode}
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
