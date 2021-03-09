defmodule NsgLoraWeb.LorawanServerLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    server =
      case NsgLora.Repo.Server.read(node()) do
        {:ok, server} -> server
        _ -> %{}
      end

    config = server[:config] || %{"http_port" => 8080, "https_port" => 8443}

    app = started?()

    {:ok,
     assign(socket,
       server_up: !!app,
       config: config,
       err: %{}
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
        Application.ensure_all_started(:lorawan_server)
        socket = put_flash(socket, :info, gettext("Server started"))
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

  def handle_event("config_validate", params = %{"config" => config}, socket) do
    err = validate(config)
    {:noreply, assign(socket, config: config, err: err)}
  end

  def handle_event("config", params = %{"config" => config}, socket) do
    IO.inspect(params, label: "SAVE")

    {:noreply, assign(socket, config: socket.assigns.config)}
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
    %{
      "http_port" => port_validate(config["http_port"]),
      "https_port" => port_validate(config["https_port"])
    }
  end

  defp port_validate(str) do
    str = String.trim(str)

    case str do
      "" ->
        ""

      _ ->
        case Integer.parse(str) do
          {n, ""} ->
            cond do
              n <= 0 or n > 65535 -> gettext("Must be from 1 to 65535")
              true -> ""
            end

          _ ->
            gettext("Must be number")
        end
    end
  end
end
