defmodule NsgLoraWeb.LorawanServerLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext

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
    {:noreply, assign(socket, uri: URI.parse(uri))}
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

        {:noreply, assign(socket, server_up: server_up)}

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
    {:noreply, assign(socket, server_up: false, alert: %{hidden: true})}
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
    |> port_validate("http_port", config["http_port"])
    |> port_validate("https_port", config["https_port"])
  end

  defp port_validate(errmap, id, value) do
    value = String.trim(value)

    case value do
      "" ->
        errmap

      _ ->
        case Integer.parse(value) do
          {n, ""} ->
            cond do
              n <= 0 or n > 65535 -> Map.put(errmap, id, gettext("Must be from 1 to 65535"))
              true -> errmap
            end

          _ ->
            Map.put(errmap, id, gettext("Must be number"))
        end
    end
  end

  defp get_server_or_default(sname) do
    case NsgLora.Repo.Server.read(node()) do
      {:ok, server = %NsgLora.Repo.Server{}} ->
        server

      _ ->
        %NsgLora.Repo.Server{sname: sname, config: %{"http_port" => 8080, "https_port" => 8443}}
    end
  end

  def lorawan_server_start() do
    server = get_server_or_default(node())
    config = server.config

    http_admin_listen =
      case Integer.parse(config["http_port"]) do
        {n, _} -> [port: n]
        _ -> []
      end

    Application.put_env(:lorawan_server, :http_admin_listen, http_admin_listen)

    Application.ensure_all_started(:lorawan_server)
  end
end
