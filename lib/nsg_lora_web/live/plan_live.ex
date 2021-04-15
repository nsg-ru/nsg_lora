defmodule NsgLoraWeb.PlanLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.LoraApps.SerLocalization
  @impl true

  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(NsgLora.PubSub, "nsg-localization")

    [y, x] = SerLocalization.get_fp()

    training =
      case SerLocalization.get_mode() do
        :collect -> true
        _ -> false
      end

    measures = SerLocalization.get_rssi_measures() |> parce_rssi_measures()

    socket =
      assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
      |> assign(
        tp_position: %{x: x, y: y},
        fp_show: false,
        training: training,
        rssi_measures: measures
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("tp_position", %{"lat" => y, "lng" => x}, socket) do
    SerLocalization.set_fp([y, x])
    {:noreply, socket}
  end

  def handle_event("training_mode_toggle", _params, socket) do
    training = !socket.assigns.training
    SerLocalization.set_mode((training && :collect) || :localization)
    {:noreply, assign(socket, training: training)}
  end

  def handle_event("fp_show_toggle", _params, socket) do
    fp_show = !socket.assigns.fp_show

    socket =
      case fp_show do
        true ->
          add_show_fp_events(socket)

        _ ->
          push_event(socket, "clear_fp_position", %{})
      end

    {:noreply, assign(socket, fp_show: fp_show)}
  end

  def handle_event("delete_fp", %{"id" => id}, socket) do
    NsgLora.Repo.Localization.delete(id)
    {:noreply, redraw_fp_events(socket)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_marker, position}, socket) do
    {:noreply, push_event(socket, "new_position", %{position: position})}
  end

  def handle_info({:update_tp, position}, socket) do
    {:noreply, push_event(socket, "update_tp", %{position: position})}
  end

  def handle_info({:new_fp, %{id: id, coord: position}}, socket) do
    {:noreply,
     push_event(socket, "fp_position", %{id: id, position: position})
     |> assign(rssi_measures: "")}
  end

  def handle_info({:rssi_measures, measures}, socket) do
    {:noreply, assign(socket, rssi_measures: parce_rssi_measures(measures))}
  end

  def handle_info({:training, t}, socket) do
    {:noreply, assign(socket, training: t)}
  end

  defp parce_rssi_measures(measures) do
    inspect(measures, pretty: true)
  end

  defp add_show_fp_events(socket) do
    {:ok, fps} = NsgLora.Repo.Localization.all()

    fps
    |> Enum.reduce(socket, fn fp, socket ->
      push_event(socket, "fp_position", %{id: fp.id, position: fp.coord})
    end)
  end

  defp redraw_fp_events(socket) do
    socket
    |> push_event("clear_fp_position", %{})
    |> add_show_fp_events()
  end
end
