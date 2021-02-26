defmodule NsgLoraWeb.HeaderComponent do
  use NsgLoraWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("toggle-lang", _params, socket) do
    NsgLoraWeb.Live.get_lang(socket.assigns.admin, toggle: true)

    {:noreply, push_redirect(socket, to: socket.assigns.path)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params, assigns: socket.assigns)
    {:noreply, socket}
  end
end
