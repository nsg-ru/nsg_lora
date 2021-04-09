defmodule NsgLoraWeb.MapLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.LoraApps.SerRak7200

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
    Phoenix.PubSub.subscribe(NsgLora.PubSub, "nsg-rak7200")
    markers_qty = 8

    {:ok,
     socket
     |> assign(
       # uploaded_files: [],
       play: true,
       markers_qty: markers_qty,
       markers_qty_err: false,
       bs_position: SerRak7200.get_bs_position(),
       first_marker_id: 0,
       last_marker_id: 0
     )
     |> allow_upload(:markers, accept: ~w(.json), max_entries: 1)
     |> show_last_markers(-markers_qty)}
  end

  @impl true
  def handle_event("bs_position", %{"lat" => lat, "lng" => lon}, socket) do
    new_position = %{lat: lat, lon: lon}
    SerRak7200.set_bs_position(new_position)
    {:noreply, assign(socket, bs_position: new_position)
    |> push_event("clear_markers", %{})
    |> show_last_markers(-socket.assigns.markers_qty)
  }
  end

  def handle_event("toggle-play-pause", _, socket) do
    play = !socket.assigns.play

    case play do
      true ->
        socket = assign(socket, play: true)

        {:noreply, push_event(socket, "clear_markers", %{})
        |> show_last_markers(-socket.assigns.markers_qty)
      }

      _ ->
        {:noreply, assign(socket, play: false)}
    end
  end

  def handle_event("clear", _params, socket) do
    {:noreply, push_event(socket, "clear_markers", %{})
    |> show_last_markers(-socket.assigns.markers_qty)
  }
  end

  def handle_event("all", _params, socket) do
    {:noreply, push_event(socket, "clear_markers", %{})
    |> show_last_markers(:all)
  }
  end

  def handle_event("markers_qty", %{"qty" => qty}, socket) do
    case Integer.parse(qty) do
      {qty, ""} when qty > 0 ->
        {:noreply, assign(socket, markers_qty: qty, markers_qty_err: false)}

      _ ->
        {:noreply, assign(socket, markers_qty_err: true)}
    end
  end

  def handle_event("markers_save", _params, %{assigns: %{play: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("markers_save", _params, socket) do
    with [{:ok, json}] <-
           consume_uploaded_entries(socket, :markers, fn %{path: path}, _entry ->
             File.read(path)
           end),
         {:ok, markers} <- Jason.decode(json) do
      markers =
        markers
        |> Enum.map(fn marker ->
          marker
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Enum.into(%{})
        end)

      Process.send(self(), {:show_markers, markers}, [])
      {:noreply, push_event(socket, "clear_markers", %{})}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  @impl true
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

    {:noreply, assign(socket, last_marker_id: marker.id) |> push_event("new_sighting", marker)}
  end

  def handle_info({:show_markers, markers}, socket) do
    socket =
      markers
      |> Enum.reduce(socket, fn marker, socket ->
        distance =
          Geocalc.distance_between(
            [socket.assigns.bs_position.lat, socket.assigns.bs_position.lon],
            [
              marker.lat,
              marker.lon
            ]
          )
          |> round()

        marker = Map.put(marker, :distance, distance)
        push_event(socket, "new_sighting", marker)
      end)

    {:noreply, socket}
  end

  defp show_last_markers(socket, n) do
    markers = SerRak7200.get_markers(n)
    Process.send(self(), {:show_markers, markers}, [])

    case markers do
      [%{id: id} | _] ->
        qty = case n do
          :all -> length(markers)
            n -> -n
        end
        socket |> assign(first_marker_id: id, last_marker_id: id + qty)
      _ -> socket
    end
  end
end
