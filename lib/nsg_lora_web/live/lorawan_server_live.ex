defmodule NsgLoraWeb.LorawanServerLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
    {:ok, socket}
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    {:noreply, assign(socket, uri: URI.parse(uri))}
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end
end
