use Mix.Config

import_config "prod.exs"

config :nsg_lora, :lora, gpio_reset_pin: 27
