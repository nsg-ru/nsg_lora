defmodule NsgLora.LoraApp.Rak7200 do
  @behaviour :lorawan_application

  require NsgLora.LoraWan

  def init(app) do
    IO.inspect(app, label: "INIT")
    :ok
  end

  def handle_join({_network, _profile, _device} = a, {_mac, _rxq} = b, _dev_addr = c) do
    IO.inspect({a, b, c}, label: "JOIN")
    :ok
  end

  def handle_uplink({_network, _profile, _node}, _rxq, {:missed, _receipt}, _frame) do
    IO.puts("UPLINK MISSED")
    :retransmit
  end

  def handle_uplink(context, rxq, last_missed, frame) do
    IO.inspect([context, rxq, last_missed, frame], label: "UPLINK")
    # accept and wait for deduplication
    {:ok, []}
  end

  def handle_rxq({network, profile, node}, gateways, will_reply, frame, state) do
    IO.inspect([{network, profile, node}, gateways, will_reply, frame, state], label: "RXQ")
    data = IO.inspect(NsgLora.LoraWan.frame(frame)[:data])

    :lorawan_application_backend.cayenne_decode(data)
    |> IO.inspect()

    :ok
  end

  def handle_delivery({network, profile, node}, result, receipt) do
    IO.inspect([{network, profile, node}, result, receipt], label: "DELIVERY")
    :ok
  end
end
