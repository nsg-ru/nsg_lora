defmodule NsgLoraWeb.MQTTServerComponent do
  use Phoenix.LiveComponent
  import NsgLoraWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, xxx: "ru")}
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(%{event: event, params: params})
    {:noreply, socket}
  end
end
