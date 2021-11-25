defmodule NsgLoraWeb.SmtpLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext
  alias NsgLora.Repo.Config
  alias NsgLora.Validate

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    {:ok,
     assign(socket,
       config: get_config(),
       err: %{},
       input: false,
       play_log: true,
       smtp_log: "SMTP Log"
     )}
  end

  @impl true
  def handle_event("config_validate", %{"config" => config}, socket) do
    config = socket.assigns.config |> Map.merge(config)
    err = validate(config)
    {:noreply, assign(socket, config: config, err: err, input: true)}
  end

  def handle_event("config", %{"config" => config}, socket) do
    config = socket.assigns.config |> Map.merge(config)

    case validate(config) do
      err when err == %{} ->
        Config.write(:smtp_relay, config["relay"])
        Config.write(:smtp_username, config["username"])
        Config.write(:smtp_password, config["password"])
        Config.write(:smtp_subject, config["subject"])
        Config.write(:smtp_sender, config["sender"])
        Config.write(:smtp_receiver, config["receiver"])

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

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  defp get_config() do
    %{
      "relay" => Config.read_value(:smtp_relay) || "",
      "username" => Config.read_value(:smtp_username) || "",
      "password" => Config.read_value(:smtp_password) || "",
      "subject" => Config.read_value(:smtp_subject) || "",
      "sender" => Config.read_value(:smtp_sender) || "",
      "receiver" => Config.read_value(:smtp_receiver) || ""
    }
  end

  defp validate(config) do
    %{}
    |> Validate.trim("password", config["password"])
  end
end
