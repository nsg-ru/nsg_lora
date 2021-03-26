defmodule NsgLoraWeb.BSLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.Validate
  alias NsgLora.Repo.BS

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    Phoenix.PubSub.subscribe(NsgLora.PubSub, "exec_ser")

    bs = get_bs_or_default(node())
    bs_up = NsgLora.ExecSer.port_alive?(:packet_forwarder)

    {:ok,
     assign(socket,
       bs_adm_state: bs.adm_state,
       bs_up: bs_up,
       config: bs.gw,
       err: %{},
       input: false,
       channel_plans: NsgLora.Config.channel_plan(:list),
       lora_modules: NsgLora.Config.lora_module(:list),
       bs_log: NsgLora.ExecSer.get_data(:packet_forwarder),
       play_log: true
     )}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    bs_adm_state = !socket.assigns.bs_adm_state

    case bs_adm_state do
      true ->
        save_bs_adm_state(true)

        socket =
          case bs_start() do
            {:ok, _} ->
              socket

            {:error, reason} ->
              put_flash(
                socket,
                :error,
                gettext("Base station not started") <> ": " <> inspect(reason)
              )
          end

        {:noreply, assign(socket, bs_adm_state: true)}

      _ ->
        case socket.assigns.bs_up do
          true ->
            {:noreply,
             assign(socket,
               alert: %{
                 hidden: false,
                 text: gettext("Do you want to stop Lora base station?"),
                 id: "bs_down"
               }
             )}

          _ ->
            save_bs_adm_state(false)
            {:noreply, assign(socket, bs_adm_state: false)}
        end
    end
  end

  def handle_event("alert-cancel", _, socket) do
    {:noreply, assign(socket, alert: %{hidden: true})}
  end

  def handle_event("alert-ok", %{"id" => "bs_down"}, socket) do
    save_bs_adm_state(false)
    NsgLora.ExecSer.port_close(:packet_forwarder)
    {:noreply, assign(socket, bs_adm_state: false, alert: %{hidden: true})}
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

        case BS.write(%{bs | gw: config}) do
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

  def handle_event("toggle-log", _, socket) do
    play_log = !socket.assigns.play_log

    case play_log do
      true ->
        {:noreply,
         assign(socket,
           play_log: play_log,
           bs_log: NsgLora.ExecSer.get_data(:packet_forwarder)
         )}

      _ ->
        {:noreply, assign(socket, play_log: play_log)}
    end
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

  def handle_info({:get_data, :packet_forwarder}, socket) do
    case socket.assigns.play_log do
      true ->
        {:noreply, assign(socket, bs_log: NsgLora.ExecSer.get_data(:packet_forwarder))}

      _ ->
        {:noreply, socket}
    end
  end

  def get_bs_or_default(sname) do
    case BS.read(node()) do
      {:ok, bs = %BS{}} ->
        bs

      _ ->
        %BS{
          sname: sname,
          gw: %{
            "gateway_ID" => "0000000000000000",
            "server_address" => "localhost",
            "serv_port_down" => "1680",
            "serv_port_up" => "1680",
            "channel_plan" => "RU864-870",
            "lora_module" => "NSGLoRa_spi"
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

  def bs_start() do
    bs = get_bs_or_default(node())
    module = bs.gw["lora_module"] || "default"

    case bs.adm_state do
      true ->
        exit_packet_forwarder()
        create_gw_config_file(bs)
        reset_module()
        path = get_lora_pkt_fwd_path(module)
        NsgLora.ExecSer.start_child(%{name: :packet_forwarder, path: path})

      _ ->
        {:error, gettext("Base station adm state is down")}
    end
  end

  defp create_gw_config_file(bs) do
    gw = NsgLora.Config.gw(:default)
    {:ok, gw} = Jason.decode(gw)

    bs_gw = bs.gw

    gw =
      Map.merge(gw, %{
        "gateway_ID" => bs_gw["gateway_ID"],
        "server_address" => bs_gw["server_address"],
        "serv_port_down" => bs_gw["serv_port_down"] |> String.to_integer(),
        "serv_port_up" => bs_gw["serv_port_up"] |> String.to_integer()
      })

    channel_plan = NsgLora.Config.channel_plan(bs_gw["channel_plan"]) || "{}"

    channel_plan =
      case Jason.decode(channel_plan) do
        {:ok, channel_plan} -> channel_plan
        _ -> %{}
      end

    lora_module = NsgLora.Config.lora_module(bs_gw["lora_module"]) || "{}"

    lora_module =
      case Jason.decode(lora_module) do
        {:ok, lora_module} -> lora_module
        _ -> %{}
      end

    phy = Map.merge(channel_plan, lora_module)

    {:ok, json} =
      %{"SX1301_conf" => phy, "gateway_conf" => gw}
      |> Jason.encode(pretty: true)

    path = Application.app_dir(:nsg_lora) <> "/priv/lora/global_conf.json"
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

  defp save_bs_adm_state(adm_state) do
    bs = get_bs_or_default(node())
    BS.write(%{bs | adm_state: adm_state})
  end

  defp get_lora_pkt_fwd_path(module) do
    case Application.get_env(:nsg_lora, :lora)[:lora_pkt_fwd_path] do
      path when is_binary(path) ->
        path

      _ ->
        nsg_executable =
          case module do
            "RAK2247_usb" -> "lora_pkt_fwd_rak2247usb"
            "NSGLoRa_spi" -> "lora_pkt_fwd_nsg"
            _ -> ""
          end

        case System.find_executable(nsg_executable) do
          path when is_binary(path) ->
            path

          _ ->
            Application.app_dir(:nsg_lora) <>
              "/priv/lora/" <>
              module <>
              "/lora_pkt_fwd"
        end
    end
  end

  def get_gw_id_from_eth_mac() do
    with {res, 0} <- System.cmd("ip", ["addr"]),
         [_, x1, x2, x3, x4, x5, x6] <-
           Regex.run(
             ~r/ether\s+([[:xdigit:]]{2,2}):([[:xdigit:]]{2,2}):([[:xdigit:]]{2,2}):([[:xdigit:]]{2,2}):([[:xdigit:]]{2,2}):([[:xdigit:]]{2,2})/,
             res
           ) do
      "#{x1}#{x2}#{x3}FFFF#{x4}#{x5}#{x6}" |> String.upcase()
    else
      _ -> "FFFFFFFFFFFFFFFF"
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
