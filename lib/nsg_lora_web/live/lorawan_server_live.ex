defmodule NsgLoraWeb.LorawanServerLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.Validate
  alias NsgLora.Repo.Server

  @impl true
  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(NsgLora.PubSub, "lager_ring")
    Phoenix.PubSub.subscribe(NsgLora.PubSub, "system")

    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
    server = get_server_or_default(node())
    config = server.config

    app = started?()

    {:ok,
     assign(socket,
       server_adm_state: server.adm_state,
       server_up: !!app,
       config: config,
       err: %{},
       input: false,
       play_log: true,
       log: NsgLora.LagerRing.get_log()
     )}
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    socket = assign(socket, uri: URI.parse(uri))
    {:noreply, assign(socket, server_url: lorawan_server_url(socket))}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    server_adm_state = !socket.assigns.server_adm_state

    case server_adm_state do
      true ->
        save_server_adm_state(true)

        socket =
          case lorawan_server_start() do
            {:ok, _} ->
              put_flash(socket, :info, gettext("Server started"))

            {:error, reason} ->
              put_flash(socket, :error, gettext("Server not started") <> ": " <> inspect(reason))
          end

        {:noreply,
         assign(socket,
           server_adm_state: true,
           server_up: !!started?(),
           server_url: lorawan_server_url(socket)
         )}

      _ ->
        case socket.assigns.server_up do
          true ->
            {:noreply,
             assign(socket,
               alert: %{
                 hidden: false,
                 text: gettext("Do you want to stop Lorawan server?"),
                 id: "server_down"
               }
             )}

          _ ->
            {:noreply, assign(socket, server_adm_state: false)}
        end
    end
  end

  def handle_event("alert-cancel", _, socket) do
    {:noreply, assign(socket, alert: %{hidden: true})}
  end

  def handle_event("alert-ok", %{"id" => "server_down"}, socket) do
    save_server_adm_state(false)
    Application.stop(:lorawan_server)
    socket = put_flash(socket, :info, gettext("Server closed"))

    {:noreply,
     assign(socket, server_adm_state: false, server_up: !!started?(), alert: %{hidden: true})}
  end

  def handle_event("config_validate", %{"config" => config}, socket) do
    err = validate(config)
    {:noreply, assign(socket, config: config, err: err, input: true)}
  end

  def handle_event("config", %{"config" => config}, socket) do
    case validate(config) do
      err when err == %{} ->
        server = get_server_or_default(node())

        case Server.write(%{server | config: config}) do
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

  def handle_event("toggle-play-pause", _, socket) do
    play_log = !socket.assigns.play_log

    case play_log do
      true ->
        {:noreply,
         assign(socket,
           play_log: play_log,
           log: NsgLora.LagerRing.get_log()
         )}

      _ ->
        {:noreply, assign(socket, play_log: play_log)}
    end
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:get_log, socket) do
    case socket.assigns.play_log do
      true ->
        {:noreply, assign(socket, log: NsgLora.LagerRing.get_log())}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(:lorawan_server_started, socket) do
    {:noreply, assign(socket, server_up: !!started?())}
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
    case Server.read(node()) do
      {:ok, server = %Server{}} ->
        server

      _ ->
        %Server{
          sname: sname,
          config: %{
            "http_port" => "8080",
            "https_port" => "8443",
            "packet_forwarder_port" => "1680",
            "certfile" => "",
            "cacertfile" => "",
            "keyfile" => ""
          }
        }
    end
  end

  def lorawan_server_start(opts \\ []) do
    server =
      case opts[:server] do
        server = %Server{} -> server
        _ -> get_server_or_default(node())
      end

    case server.adm_state do
      true ->
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

        Application.put_env(:lorawan_server, :applications, [
          {"semtech-mote", :lorawan_application_semtech_mote},
          {"nsg-debug", NsgLora.LoraApps.Debug},
          {"nsg-rak7200", NsgLora.LoraApp},
          {"nsg-localization", NsgLora.LoraApp},
          {"nsg-smtp", NsgLora.LoraApp}
        ])

        Application.ensure_all_started(:lorawan_server)

      _ ->
        {:error, gettext("Server adm state is down")}
    end
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

  defp save_server_adm_state(adm_state) do
    server = get_server_or_default(node())
    Server.write(%{server | adm_state: adm_state})
  end
end
