defmodule NsgLoraWeb.MapLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
    Phoenix.PubSub.subscribe(NsgLora.PubSub, "nsg-rak7200")

    {:ok, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  def handle_info({:new_marker, marker}, socket) do
    {:noreply, push_event(socket, "new_sighting", marker)}
  end
end
