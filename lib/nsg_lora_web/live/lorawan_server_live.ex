defmodule NsgLoraWeb.LorawanServerLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    app = started?()

    {:ok,
     assign(socket,
       server_up: !!app
     )}
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    {:noreply, assign(socket, uri: URI.parse(uri))}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    server_up = !socket.assigns.server_up

    socket =
      case server_up do
        true -> put_flash(socket, :info, gettext("Server started"))
        _ -> put_flash(socket, :error, gettext("Server closed"))
      end

    {:noreply, assign(socket, server_up: server_up)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  def started?() do
    Application.started_applications()
    |> Enum.find(fn {name, _, _} -> name == :lorawan_server end)
  end
end
