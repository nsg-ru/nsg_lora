defmodule NsgLoraWeb.MapLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.LoraApps.SerRak7200

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
    Phoenix.PubSub.subscribe(NsgLora.PubSub, "nsg-rak7200")
    Process.send(self(), :init, [])
    {:ok, assign(socket, play: true, bs_position: SerRak7200.get_bs_position())}
  end

  @impl true
  def handle_event("bs_position", %{"lat" => lat, "lng" => lon}, socket) do
    new_position = %{lat: lat, lon: lon}
    SerRak7200.set_bs_position(new_position)
    {:noreply, assign(socket, bs_position: new_position)}
  end

  def handle_event("toggle-play-pause", _, socket) do
    play = !socket.assigns.play

    case play do
      true ->
        {:noreply,
         assign(socket,
           play: play
         )}

      _ ->
        {:noreply, assign(socket, play: play)}
    end
  end

  def handle_event("clear", _params, socket) do
    Process.send(self(), :init, [])
    {:noreply, push_event(socket, "clear_markers", %{})}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:init, socket) do
    SerRak7200.get_markers(-8)
    |> Enum.each(fn marker ->
      Phoenix.PubSub.broadcast(
        NsgLora.PubSub,
        "nsg-rak7200",
        {:new_marker, marker}
      )
    end)

    {:noreply, socket}
  end

  def handle_info({:new_marker, _marker}, %{assigns: %{play: false}} = socket) do
    {:noreply, socket}
  end

  def handle_info({:new_marker, marker}, socket) do
    distance =
      Geocalc.distance_between([socket.assigns.bs_position.lat, socket.assigns.bs_position.lon], [
        marker.lat,
        marker.lon
      ])
      |> round()

    marker = Map.put(marker, :distance, distance)

    {:noreply, push_event(socket, "new_sighting", marker)}
  end
end
