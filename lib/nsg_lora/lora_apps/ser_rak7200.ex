defmodule NsgLora.LoraApps.SerRak7200 do
  use GenServer
  require NsgLora.LoraWan

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    IO.puts("INIT NsgLora.LoraApps.SerRak7200")
    {:ok, %{}}
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

        %{
          freq: rxq[:freq],
          rssi: rxq[:rssi],
          lsnr: rxq[:lsnr],
          lat: lat,
          lon: lon
        }
        |> IO.inspect()

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def rxq(params) do
    GenServer.cast(__MODULE__, {:rxq, params})
  end
end
