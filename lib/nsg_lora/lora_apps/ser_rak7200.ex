defmodule NsgLora.LoraApps.SerRak7200 do
  use GenServer
  require NsgLora.LoraWan
  alias NsgLora.LoraWan
  require Logger

  @emul_interval 10_000

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    Process.send_after(self(), :emul, @emul_interval)

    {:ok,
     %{
       bs_position: %{lat: 55.777594, lon: 37.737926},
       markers: CircularBuffer.new(1024)
     }}
  end

  @impl true
  def handle_info(:emul, state) do
    rxq(%{
      frame:
        LoraWan.frame(
          data:
            <<0x0188::16, 55_777_594 + Enum.random(-10000..10000)::32,
              37_737_926 + Enum.random(-10000..10000)::32, 188::32>>
        ),
      gateways: [
        {"FFFFFF000000",
         LoraWan.rxq(
           freq: 868.1,
           rssi: -55,
           lsnr: 11
         )}
      ]
    })

    Process.send_after(self(), :emul, @emul_interval)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:rxq, %{frame: frame, gateways: [{_mak, rxq} | _] = _gateways}}, state) do
    frame = NsgLora.LoraWan.frame(frame)

    data = frame[:data]

    data =
      case rak7200_decode(data, %{}) do
        {:ok, data} ->
          data

        {:error, _} ->
          {_, data} = rak7200_decode(data, %{}, :gps4)
          data
      end

    case data do
      %{gps: %{lat: lat, lon: lon}} ->
        rxq = NsgLora.LoraWan.rxq(rxq)

        marker = %{
          date: NaiveDateTime.local_now() |> to_string(),
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

  def get_markers(:all) do
    GenServer.call(__MODULE__, :get_markers)
  end

  def get_markers(n) do
    GenServer.call(__MODULE__, {:get_markers, n})
  end

  defp rak7200_decode(rest, acc, opts \\ nil)

  defp rak7200_decode(<<>>, acc, _opts) do
    {:ok, acc}
  end

  defp rak7200_decode(<<0x0188::16, lat::24, lon::24, alt::24, rest::binary>>, acc, :gps4) do
    rak7200_decode(
      rest,
      Map.put(acc, :gps, %{
        lat: lat |> precision(4),
        lon: lon |> precision(4),
        alt: alt |> precision(2)
      })
    )
  end

  defp rak7200_decode(<<0x0188::16, lat::32, lon::32, alt::32, rest::binary>>, acc, _opts) do
    rak7200_decode(
      rest,
      Map.put(acc, :gps, %{
        lat: lat |> precision(6),
        lon: lon |> precision(6),
        alt: alt |> precision(2)
      })
    )
  end

  defp rak7200_decode(<<0x0371::16, x::16, y::16, z::16, rest::binary>>, acc, _opts) do
    rak7200_decode(
      rest,
      Map.put(acc, :acceleration, %{
        x: x |> precision(3),
        y: y |> precision(3),
        z: z |> precision(3)
      })
    )
  end

  defp rak7200_decode(<<0x0586::16, x::16, y::16, z::16, rest::binary>>, acc, _opts) do
    rak7200_decode(
      rest,
      Map.put(acc, :gyroscope, %{
        x: x |> precision(2),
        y: y |> precision(2),
        z: z |> precision(2)
      })
    )
  end

  defp rak7200_decode(<<0x0902::16, x::16, rest::binary>>, acc, _opts) do
    rak7200_decode(
      rest,
      Map.put(acc, :magnetometer, (acc[:magnetometer] || %{}) |> Map.put(:x, x |> precision(2)))
    )
  end

  defp rak7200_decode(<<0x0A02::16, y::16, rest::binary>>, acc, _opts) do
    rak7200_decode(
      rest,
      Map.put(acc, :magnetometer, (acc[:magnetometer] || %{}) |> Map.put(:y, y |> precision(2)))
    )
  end

  defp rak7200_decode(<<0x0B02::16, z::16, rest::binary>>, acc, _opts) do
    rak7200_decode(
      rest,
      Map.put(acc, :magnetometer, (acc[:magnetometer] || %{}) |> Map.put(:z, z |> precision(2)))
    )
  end

  defp rak7200_decode(<<0x0802::16, batt::16, rest::binary>>, acc, _opts) do
    rak7200_decode(
      rest,
      Map.put(acc, :battery, batt |> precision(2))
    )
  end

  defp rak7200_decode(rest, acc, _opts) do
    Logger.error("Bad payload: #{rest |> Base.encode16()}")

    {:error, acc}
  end

  defp precision(val, n) do
    (val * :math.pow(10, -n)) |> Float.round(n)
  end
end
