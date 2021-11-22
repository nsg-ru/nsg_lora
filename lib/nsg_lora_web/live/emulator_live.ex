defmodule NsgLoraWeb.EmulatorLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    is_started = started?()

    {:ok,
     assign(socket,
       config: %{},
       err: %{},
       emul_state: is_started,
       emul_up: is_started,
       input: false
     )}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    case started?() do
      true -> stop_lge()
      _ -> start_lge()
    end

    is_started = started?()
    {:noreply, assign(socket, emul_up: is_started, emul_state: is_started)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  defp started?() do
    Application.started_applications()
    |> Enum.find(fn {name, _, _} -> name == :lge end)
    |> Kernel.!()
    |> Kernel.!()
  end

  def start_lge() do
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

    Application.ensure_all_started(:lge)
  end

  def stop_lge() do
    Application.stop(:lge)
  end
end
