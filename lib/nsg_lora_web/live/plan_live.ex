defmodule NsgLoraWeb.PlanLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.LoraApps.SerLocalization
  @impl true

  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(NsgLora.PubSub, "nsg-localization")

    [y, x] = SerLocalization.get_fp()

    socket =
      assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
      |> assign(tp_position: %{x: x, y: y})

    {:ok, socket}
  end

  @impl true
  def handle_event("tp_position", %{"lat" => y, "lng" => x}, socket) do
    IO.inspect([y, x])
    SerLocalization.set_fp([y, x])
    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_marker, position}, socket) do
    {:noreply, push_event(socket, "new_position", %{position: position})}
  end
end
