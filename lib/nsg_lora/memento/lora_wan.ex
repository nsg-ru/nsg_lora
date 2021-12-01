defmodule NsgLora.LoraWan do
  require Record

  Record.defrecord(
    :user,
    Record.extract(:user, from: "deps/lorawan_server/include/lorawan.hrl")
  )

  Record.defrecord(
    :frame,
    Record.extract(:frame, from: "deps/lorawan_server/include/lorawan.hrl")
  )

  Record.defrecord(
    :rxq,
    Record.extract(:rxq, from: "deps/lorawan_server/include/lorawan_db.hrl")
  )

  Record.defrecord(
    :profile,
    Record.extract(:profile, from: "deps/lorawan_server/include/lorawan_db.hrl")
  )

  Record.defrecord(
    :node,
    Record.extract(:node, from: "deps/lorawan_server/include/lorawan_db.hrl")
  )

  Record.defrecord(
    :network,
    Record.extract(:network, from: "deps/lorawan_server/include/lorawan_db.hrl")
  )

  def net_ru868(name) when is_binary(name) do
    network(
      name: name,
      netid: <<0, 0, 0>>,
      region: "RU868",
      tx_codr: "4/5",
      join1_delay: 5,
      join2_delay: 6,
      rx1_delay: 1,
      rx2_delay: 2,
      gw_power: 16,
      max_eirp: 16,
      max_power: 0,
      min_power: 7,
      max_datr: 5,
      dcycle_init: 0,
      rxwin_init: {0, 0, 869.1},
      init_chans: [{0, 1}],
      cflist: :undefined
    )
  end

  def net_eu868(name) when is_binary(name) do
    network(
      name: name,
      netid: <<0, 0, 0>>,
      region: "EU868",
      tx_codr: "4/5",
      join1_delay: 5,
      join2_delay: 6,
      rx1_delay: 1,
      rx2_delay: 2,
      gw_power: 16,
      max_eirp: 16,
      max_power: 0,
      min_power: 7,
      max_datr: 5,
      dcycle_init: 0,
      rxwin_init: {0, 0, 869.525},
      init_chans: [{0, 2}],
      cflist: :undefined
    )
  end
end
