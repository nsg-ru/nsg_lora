import Config

# TODO add reading params from env
config :nsg_lora, NsgLoraWeb.Endpoint,
  https: [
    port: 4443,
    cipher_suite: :strong,
    keyfile: "/etc/stunnel/https_auto.key",
    certfile: "/etc/stunnel/https_auto.cert",
    transport_options: [socket_opts: [:inet6]]
  ],
  url: [host: "localhost", port: 4443]

config :mnesia,
  dir: '/usr/lib/lora/Mnesia'

config :nsg_lora, :lora,
  lora_gw_config_path: "/etc/lora/global_conf.json",
  packet_forwarder_path: "/usr/bin/lora_pkt_fwd",
  gpio_reset_pin: 27
