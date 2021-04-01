defmodule NsgLoraWeb.MapLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.LoraApps.SerRak7200

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
    Phoenix.PubSub.subscribe(NsgLora.PubSub, "nsg-rak7200")

    SerRak7200.get_markers(-8)
    |> Enum.each(fn marker ->
      Phoenix.PubSub.broadcast(
        NsgLora.PubSub,
        "nsg-rak7200",
        {:new_marker, marker}
      )
    end)

    {:ok, assign(socket, bs_position: SerRak7200.get_bs_position())}
  end

  @impl true
  def handle_event("bs_position", %{"lat" => lat, "lng" => lon}, socket) do
    new_position = %{lat: lat, lon: lon}
    SerRak7200.set_bs_position(new_position)
    {:noreply, assign(socket, bs_position: new_position)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  def handle_info({:new_marker, marker}, socket) do
    {:noreply, push_event(socket, "new_sighting", marker)}
  end
end
