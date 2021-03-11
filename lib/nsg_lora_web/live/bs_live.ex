defmodule NsgLoraWeb.BSLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.Validate

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))
    bs = get_bs_or_default(node())
    {:ok, assign(socket, bs_up: true, config: bs.gw, err: %{}, input: false)}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    bs_up = !socket.assigns.bs_up

    case bs_up do
      true ->
        create_gw_config_file()
        socket =
          case {:ok, nil} do
            {:ok, _} ->
              put_flash(socket, :info, gettext("Base station started"))

            {:error, reason} ->
              put_flash(
                socket,
                :error,
                gettext("Base station not started") <> ": " <> inspect(reason)
              )
          end

        {:noreply, assign(socket, bs_up: true)}

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
    socket = put_flash(socket, :info, gettext("Base station closed"))
    {:noreply, assign(socket, bs_up: false, alert: %{hidden: true})}
  end

  def handle_event("config_validate", %{"config" => config}, socket) do
    err = validate(config)
    {:noreply, assign(socket, config: config, err: err, input: true)}
  end

  def handle_event("config", %{"config" => config}, socket) do
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

  defp get_bs_or_default(sname) do
    case NsgLora.Repo.BS.read(node()) do
      {:ok, bs = %NsgLora.Repo.BS{}} ->
        bs

      _ ->
        %NsgLora.Repo.BS{
          sname: sname,
          gw: %{
            "gateway_ID" => "000956FFFE3208BB",
            "serv_port_down" => 1680,
            "serv_port_up" => 1680
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
    gw = Map.merge(gw, bs.gw)

    phy = NsgLora.Config.phy(:nsg_default)
    {:ok, phy} = Jason.decode(phy)

    {:ok, json} =
      %{"SX1301_conf" => phy, "gateway_conf" => gw}
      |> Jason.encode(pretty: true)

    path = Application.get_env(:nsg_lora, :lora)[:lora_gw_config_path]
    File.write(path, json)
  end
end
