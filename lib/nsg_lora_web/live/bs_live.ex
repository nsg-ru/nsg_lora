defmodule NsgLoraWeb.BSLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.Validate

  @channel_plans [
    "RU864-870",
    "EU863-870",
    "US902-928",
    "EU433",
    "AU-915-928",
    "CN470-510",
    "AS923",
    "KR920-923",
    "IN865-867"
  ]

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    Phoenix.PubSub.subscribe(NsgLora.PubSub, "exec_ser")

    bs = get_bs_or_default(node())
    bs_up = NsgLora.ExecSer.port_alive?(:packet_forwarder)

    {:ok,
     assign(socket,
       bs_up: bs_up,
       config: bs.gw,
       err: %{},
       input: false,
       channel_plans: @channel_plans
     )}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    bs_up = !socket.assigns.bs_up

    case bs_up do
      true ->
        exit_packet_forwarder()
        create_gw_config_file()
        reset_module()
        path = Application.get_env(:nsg_lora, :lora)[:packet_forwarder_path]

        socket =
          case NsgLora.ExecSer.start_child(%{name: :packet_forwarder, path: path}) do
            {:ok, _} ->
              socket

            {:error, reason} ->
              put_flash(
                socket,
                :error,
                gettext("Base station not started") <> ": " <> inspect(reason)
              )
          end

        {:noreply, socket}

      _ ->
        {:noreply,
         assign(socket,
           alert: %{
             hidden: false,
             text: gettext("Do you want to stop Lora base station?"),
             id: "bs_down"
           }
         )}
    end
  end

  def handle_event("alert-cancel", _, socket) do
    {:noreply, assign(socket, alert: %{hidden: true})}
  end

  def handle_event("alert-ok", %{"id" => "bs_down"}, socket) do
    NsgLora.ExecSer.port_close(:packet_forwarder)
    {:noreply, assign(socket, alert: %{hidden: true})}
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
        bs = get_bs_or_default(node())

        case NsgLora.Repo.BS.write(%{bs | gw: config}) do
          {:ok, _} ->
            {:noreply,
             assign(
               socket,
               config: config,
               err: err,
               input: false
             )}

          {:error, {:transaction_aborted, tr_err}} ->
            {:noreply, assign(socket, err: Map.put(err, "save", inspect(tr_err)))}
        end

      err ->
        {:noreply, assign(socket, config: config, err: err)}
    end
  end

  def handle_event("cancel", _, socket) do
    bs = get_bs_or_default(node())
    {:noreply, assign(socket, config: bs.gw, err: %{}, input: false)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:change_port_status, :packet_forwarder}, socket) do
    bs_up = NsgLora.ExecSer.port_alive?(:packet_forwarder)

    info =
      case bs_up do
        true -> gettext("Base station started")
        _ -> gettext("Base station closed")
      end

    socket = put_flash(socket, :info, info)
    {:noreply, assign(socket, bs_up: bs_up)}
  end

  def get_bs_or_default(sname) do
    case NsgLora.Repo.BS.read(node()) do
      {:ok, bs = %NsgLora.Repo.BS{}} ->
        bs

      _ ->
        %NsgLora.Repo.BS{
          sname: sname,
          gw: %{
            "gateway_ID" => "000956FFFE3208BB",
            "serv_port_down" => 1680,
            "serv_port_up" => 1680,
            "channel_plan" => "RU864-870"
          }
        }
    end
  end

  defp validate(config) do
    %{}
    |> Validate.hex("gateway_ID", config["gateway_ID"], 16)
    |> Validate.port("serv_port_down", config["serv_port_down"])
    |> Validate.port("serv_port_up", config["serv_port_up"])
  end

  def create_gw_config_file() do
    bs = get_bs_or_default(node())

    gw = NsgLora.Config.gw(:default)
    {:ok, gw} = Jason.decode(gw)

    bs_gw = bs.gw
    bs_gw = Map.put(bs_gw, "serv_port_down", bs_gw["serv_port_down"] |> String.to_integer())
    bs_gw = Map.put(bs_gw, "serv_port_up", bs_gw["serv_port_up"] |> String.to_integer())

    gw = Map.merge(gw, bs_gw)

    phy = NsgLora.Config.phy(:nsg_default)
    {:ok, phy} = Jason.decode(phy)

    {:ok, json} =
      %{"SX1301_conf" => phy, "gateway_conf" => gw}
      |> Jason.encode(pretty: true)

    path = Application.get_env(:nsg_lora, :lora)[:lora_gw_config_path]

    dir = Path.dirname(path)

    File.mkdir_p(dir)
    File.write(path, json)
  end

  defp exit_packet_forwarder() do
    NsgLora.ExecSer.exit(:packet_forwarder)

    case NsgLora.ExecSer.pid(:packet_forwarder) do
      nil ->
        nil

      _ ->
        Process.sleep(100)
        exit_packet_forwarder()
    end
  end

  if Application.get_env(:nsg_lora, :lora)[:gpio_reset_pin] do
    def reset_module() do
      reset_pin = Application.get_env(:nsg_lora, :lora)[:gpio_reset_pin] |> to_string()
      base_path = "/sys/class/gpio"
      File.write("#{base_path}/unexport", reset_pin)
      File.write("#{base_path}/export", reset_pin)
      File.write("#{base_path}/gpio#{reset_pin}/direction", "out")
      File.write("#{base_path}/gpio#{reset_pin}/value", "1")
      File.write("#{base_path}/gpio#{reset_pin}/value", "0")
    end
  else
    def reset_module(), do: nil
  end
end
