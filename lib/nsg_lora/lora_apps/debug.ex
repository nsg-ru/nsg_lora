defmodule NsgLora.LoraApps.Debug do
  @behaviour :lorawan_application

  require NsgLora.LoraWan

  def init(_app) do
    :ok
  end

  def handle_join({_network, _profile, _device}, {_mac, _rxq}, _dev_addr) do
    :ok
  end

  def handle_uplink({_network, _profile, _node}, _rxq, {:missed, _receipt}, _frame) do
    :retransmit
  end

  def handle_uplink(_context, _rxq, _last_missed, _frame) do
    {:ok, []}
  end

  def handle_rxq(
        {_network, _profile, _node},
        [{_mac, rxq} | _] = _gateways,
        _will_reply,
        frame,
        _state
      ) do
    rxq = NsgLora.LoraWan.rxq(rxq)
    frame = NsgLora.LoraWan.frame(frame)

    # [
    #   NaiveDateTime.local_now() |> to_string(),
    #   frame[:devaddr] |> Base.encode16()
    #   | gateways
    #     |> Enum.map(fn {mac, rxq} ->
    #       rxq = NsgLora.LoraWan.rxq(rxq)
    #       [mac: Base.encode16(mac), freq: rxq[:freq], rssi: rxq[:rssi], lsnr: rxq[:lsnr]]
    #     end)
    # ]
    # |> IO.inspect()

    res = [
      devaddr: frame[:devaddr] |> Base.encode16(),
      freq: rxq[:freq],
      rssi: rxq[:rssi],
      lsnr: rxq[:lsnr],
      data: frame[:data] |> Base.encode16()
    ]

    :lager.log(:debug, self(), "Get frame: #{inspect(res, pretty: true)}")
    :ok
  end

  def handle_delivery({_network, _profile, _node}, _result, _receipt) do
    :ok
  end
end
