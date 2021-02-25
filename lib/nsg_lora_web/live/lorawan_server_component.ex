defmodule NsgLoraWeb.LorawanServerComponent do
  use Phoenix.LiveComponent
  import NsgLoraWeb.Gettext

  @impl true
  def mount(socket) do
    Application.ensure_all_started(:lorawan_server)
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, uri: assigns.uri)}
  end

  @impl true
  def handle_event(event, params, socket) do
    {:noreply, socket}
  end
end
