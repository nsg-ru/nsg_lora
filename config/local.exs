import Config

config :nsg_lora, NsgLoraWeb.Endpoint,
  http: [port: 4000]
  config :nsg_lora, NsgLoraWeb.Endpoint,
    https: [
      port: 4443,
      cipher_suite: :strong,
      keyfile: System.get_env("NSG_LORA_SSL_KEY_PATH") || "priv/cert/selfsigned_key.pem",
      certfile: System.get_env("NSG_LORA_SSL_CERT_PATH") || "priv/cert/selfsigned.pem",
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: "localhost", port: 4443]
