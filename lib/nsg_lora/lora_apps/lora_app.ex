defmodule NsgLora.LoraApp do
  @behaviour :lorawan_application

  require NsgLora.LoraWan

  @server %{
    "nsg-rak7200" => NsgLora.LoraApps.SerRak7200,
    "nsg-localization" => NsgLora.LoraApps.SerLocalization
  }

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
    # accept and wait for deduplication
    {:ok, []}
  end

  def handle_rxq({network, profile, node}, gateways, will_reply, frame, state) do
    app =
      NsgLora.LoraWan.profile(profile)[:app]
      |> IO.inspect()

    case @server[app] do
      nil ->
        :lager.log(:error, self(), "No app server for #{app}")

      mod ->
        apply(mod, :rxq, [
          %{
            network: network,
            profile: profile,
            node: node,
            gateways: gateways,
            will_reply: will_reply,
            frame: frame,
            state: state
          }
        ])
    end

    :ok
  end

  def handle_delivery({_network, _profile, _node}, _result, _receipt) do
    :ok
  end
end
