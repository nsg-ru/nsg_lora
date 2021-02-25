defmodule NsgLoraWeb.DashboardComponent do
  use Phoenix.LiveComponent
  import NsgLoraWeb.Gettext

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, xxx: "ru")}
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(%{event: event, params: params})
    {:noreply, socket}
  end
end
