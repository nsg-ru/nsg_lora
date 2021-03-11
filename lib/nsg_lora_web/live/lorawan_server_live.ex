defmodule NsgLoraWeb.LorawanServerLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.Validate

  @default_config [
    http_admin_path: "/admin",
    map_tile_server: "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    http_custom_web: [],
    connectors: [
      lorawan_connector_amqp: ["amqp", "amqps"],
      lorawan_connector_mqtt: ["mqtt", "mqtts"],
      lorawan_connector_http: ["http", "https"],
      lorawan_connector_mongodb: ["mongodb"],
      lorawan_connector_ws: ["ws"]
    ],
    frames_before_adr: 50,
    slack_server: {'slack.com', 443},
    applications: [{"semtech-mote", :lorawan_application_semtech_mote}],
    max_lost_after_reset: 10,
    trim_interval: 3600,
    gateway_delay: 200,
    http_admin_redirect_ssl: false,
    retained_rxframes: 50,
    websocket_timeout: 3_600_000,
    ssl_options: [],
    http_extra_headers: %{},
    deduplication_delay: 200,
    http_admin_credentials: {"admin", "admin"},
    server_stats_interval: 60,
    devstat_gap: {432_000, 96},
    event_lifetime: 86400,
  ]

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
    server = get_server_or_default(node())
    config = server.config

    app = started?()

    {:ok,
     assign(socket,
       server_up: !!app,
       config: config,
       err: %{},
       input: false
     )}
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    socket = assign(socket, uri: URI.parse(uri))
    {:noreply, assign(socket, server_url: lorawan_server_url(socket))}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    server_up = !socket.assigns.server_up

    case server_up do
      true ->
        socket =
          case lorawan_server_start() do
            {:ok, _} ->
              put_flash(socket, :info, gettext("Server started"))

            {:error, reason} ->
              put_flash(socket, :error, gettext("Server not started") <> ": " <> inspect(reason))
          end

        {:noreply,
         assign(socket, server_up: !!started?(), server_url: lorawan_server_url(socket))}

      _ ->
        {:noreply,
         assign(socket,
           alert: %{
             hidden: false,
             text: gettext("Do you want to stop Lorawan server?"),
             id: "server_down"
           }
         )}
    end
  end

  def handle_event("alert-cancel", _, socket) do
    {:noreply, assign(socket, alert: %{hidden: true})}
  end

  def handle_event("alert-ok", %{"id" => "server_down"}, socket) do
    Application.stop(:lorawan_server)
    socket = put_flash(socket, :info, gettext("Server closed"))
    {:noreply, assign(socket, server_up: !!started?(), alert: %{hidden: true})}
  end

  def handle_event("config_validate", %{"config" => config}, socket) do
    err = validate(config)
    {:noreply, assign(socket, config: config, err: err, input: true)}
  end

  def handle_event("config", %{"config" => config}, socket) do
    case validate(config) do
      err when err == %{} ->
        server = get_server_or_default(node())

        case NsgLora.Repo.Server.write(%{server | config: config}) do
          {:ok, _} ->
            {:noreply,
             assign(
               socket,
               config: config,
               err: err,
               input: false
             )}

          {:error, {:transaction_aborted, tr_err}} ->
            {:noreply, assign(socket, err: Map.put(err, "save", inspect(tr_err)))}
        end

      err ->
        {:noreply, assign(socket, config: config, err: err)}
    end
  end

  def handle_event("cancel", _, socket) do
    server = get_server_or_default(node())
    {:noreply, assign(socket, config: server.config, err: %{}, input: false)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  defp started?() do
    Application.started_applications()
    |> Enum.find(fn {name, _, _} -> name == :lorawan_server end)
  end

  defp validate(config) do
    %{}
    |> Validate.port("packet_forwarder_port", config["packet_forwarder_port"])
    |> Validate.port("http_port", config["http_port"])
    |> Validate.port("https_port", config["https_port"])
  end

  defp get_server_or_default(sname) do
    case NsgLora.Repo.Server.read(node()) do
      {:ok, server = %NsgLora.Repo.Server{}} ->
        server

      _ ->
        %NsgLora.Repo.Server{
          sname: sname,
          config: %{"http_port" => 8080, "https_port" => 8443, "packet_forwarder_port" => 1680}
        }
    end
  end

  def lorawan_server_start() do
    server = get_server_or_default(node())

    config = server.config

    packet_forwarder_listen =
      case Integer.parse(config["packet_forwarder_port"]) do
        {n, _} -> [port: n]
        _ -> []
      end

    http_admin_listen =
      case Integer.parse(config["http_port"]) do
        {n, _} -> [port: n]
        _ -> []
      end

    http_admin_listen_ssl =
      case Integer.parse(config["https_port"]) do
        {n, _} ->
          [
            port: n,
            certfile: config["certfile"] |> String.trim() |> String.to_charlist(),
            cacertfile: [config["cacertfile"] |> String.trim() |> String.to_charlist()],
            keyfile: config["keyfile"] |> String.trim() |> String.to_charlist()
          ]

        _ ->
          []
      end

    Application.put_env(:lorawan_server, :http_admin_redirect_ssl, false)

    Application.put_env(:lorawan_server, :packet_forwarder_listen, packet_forwarder_listen)
    Application.put_env(:lorawan_server, :http_admin_listen, http_admin_listen)
    Application.put_env(:lorawan_server, :http_admin_listen_ssl, http_admin_listen_ssl)

    Application.ensure_all_started(:lorawan_server)
  end

  defp lorawan_server_url(socket) do
    env = Application.get_all_env(:lorawan_server)

    http =
      case env[:http_admin_listen][:port] do
        n when is_integer(n) ->
          "http://#{socket.assigns.uri.host}:#{n}"

        _ ->
          nil
      end

    https =
      case env[:http_admin_listen_ssl][:port] do
        n when is_integer(n) -> "https://#{socket.assigns.uri.host}:#{n}"
        _ -> nil
      end

    %{http: http, https: https}
  end
end
