# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :nsg_lora, NsgLoraWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "llTanzmDToCi1g6nMmuGFMQI7z6beqG/gf36gMeG49ztsns5J+PIrplOMoq+XwjP",
  render_errors: [view: NsgLoraWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: NsgLora.PubSub,
  live_view: [signing_salt: "GwFPmi9y"]

# Gettext
config :gettext, :default_locale, "ru"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mnesia,
  dir: '.mnesia/#{Mix.env()}/#{node()}'

config :nsg_lora, NsgLora.Guardian,
  issuer: "nsg_lora",
  secret_key: "99uM718KzWXfU/wxsmJzNgncrqZkRA/a3aOmkJLLDHamz7dXU3Ybbl5W9qLJKvcl"

config :nsg_lora, :lora,
  lora_gw_config_path: "./tmp/global_conf.json",
  packet_forwarder_path: "./rak2247_usb/lora_pkt_fwd"

config :lager, :crash_log, false
# Stop lager redirecting :error_logger messages
config :lager, :error_logger_redirect, false
# Stop lager removing Logger's :error_logger handler
config :lager, :error_logger_whitelist, [Logger.ErrorHandler]

config :lager,
  handlers: [
    {LagerHandler, [level: :debug]},
    {:lager_console_backend, :info}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
