defmodule NsgLoraWeb.EmulatorLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.Repo.Config
  alias NsgLora.Validate

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    is_started = started?()

    {:ok,
     assign(socket,
       config: get_config(),
       err: %{},
       emul_state: is_started,
       emul_up: is_started,
       input: false
     )}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    case started?() do
      true ->
        stop_lge()

      _ ->
        start_lge(
          interval: socket.assigns.config["interval"],
          payload: socket.assigns.config["payload"]
        )
    end

    is_started = started?()
    {:noreply, assign(socket, emul_up: is_started, emul_state: is_started)}
  end

  def handle_event("push-data", _params, socket) do
    GenServer.cast(:lge_push_data, :push)
    {:noreply, socket}
  end

  def handle_event("config_validate", %{"config" => config}, socket) do
    config = socket.assigns.config |> Map.merge(config)
    err = validate(config)
    {:noreply, assign(socket, config: config, err: err, input: true)}
  end

  def handle_event("config", %{"config" => config}, socket) do
    config = socket.assigns.config |> Map.merge(config)

    case validate(config) do
      err when err == %{} ->
        Config.write(:emulator_interval, config["interval"])
        Config.write(:emulator_payload, config["payload"])

        {:noreply,
         assign(
           socket,
           config: config,
           err: err,
           input: false
         )}

      err ->
        {:noreply, assign(socket, config: config, err: err)}
    end
  end

  def handle_event("cancel", _, socket) do
    {:noreply, assign(socket, config: get_config(), err: %{}, input: false)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  defp get_config() do
    %{
      "interval" => Config.read_value(:emulator_interval),
      "payload" => Config.read_value(:emulator_payload) || "530101000000005A"
    }
  end

  defp started?() do
    Application.started_applications()
    |> Enum.find(fn {name, _, _} -> name == :lge end)
    |> Kernel.!()
    |> Kernel.!()
  end

  defp validate(config) do
    %{}
    |> Validate.uint("interval", config["interval"])
    |> Validate.hex("payload", config["payload"])
  end

  defp start_lge(opts) do
    reset_fcnt()

    Application.put_env(:lge, :ip, {127, 0, 0, 1})
    Application.put_env(:lge, :port, 1680)

    Application.put_env(:lge, :mac, <<0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE>>)
    Application.put_env(:lge, :devaddr, 0xEEEEEEEE)

    Application.put_env(
      :lge,
      :appskey,
      <<0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE,
        0xEE>>
    )

    Application.put_env(
      :lge,
      :netwkskey,
      <<0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE,
        0xEE>>
    )

    interval = opts[:interval] || "0"

    interval =
      case interval |> String.trim() |> Integer.parse() do
        {interval, ""} ->
          interval

        _ ->
          0
      end

    Application.put_env(:lge, :interval, interval)

    payload = opts[:payload] || "530101000000005B"

    Application.put_env(
      :lge,
      :message,
      payload |> String.trim() |> String.upcase() |> Base.decode16!()
    )

    Application.ensure_all_started(:lge)
  end

  defp stop_lge() do
    Application.stop(:lge)
  end

  require NsgLora.LoraWan

  def reset_fcnt() do
    :mnesia.transaction(fn ->
      [rec] = :mnesia.read(:node, Base.decode16!("EEEEEEEE"))
      rec = NsgLora.LoraWan.node(rec, fcntup: 0, fcntdown: 0)
      NsgLora.LoraWan.node(rec)
      :mnesia.write(rec)
    end)
  end
end
