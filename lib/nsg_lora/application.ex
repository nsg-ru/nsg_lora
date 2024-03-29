defmodule NsgLora.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      # NsgLoraWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: NsgLora.PubSub},
      # Start the Endpoint (http/https)
      NsgLoraWeb.Endpoint,
      # Start a worker by calling: NsgLora.Worker.start_link(arg)
      # {NsgLora.Worker, arg}
      NsgLora.LagerRing,
      NsgLora.SmtpLog,
      NsgLora.DynSup,
      NsgLora.LoraApps.Sup,
      NsgLora.DBServer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NsgLora.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NsgLoraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
