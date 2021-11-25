defmodule NsgLora.LoraApps.Smtp do
  use GenServer
  require NsgLora.LoraWan
  alias NsgLora.Repo.Config

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:rxq, %{frame: frame}}, state) do
    frame = NsgLora.LoraWan.frame(frame)

    devaddr = frame[:devaddr] |> Base.encode16()
    data = frame[:data] |> Base.encode16()

    text = "Датчик #{devaddr}, сообщение: #{data}"

    config = get_config()

    server = [
      relay: config.relay,
      username: config.username,
      password: config.password
    ]

    IO.inspect({server, config.sender, [config.receiver], config.subject, text})
    smtp(server, config.sender, [config.receiver], config.subject, text)
    {:noreply, state}
  end

  def rxq(params) do
    GenServer.cast(__MODULE__, {:rxq, params})
  end

  defp get_config() do
    %{
      relay: Config.read_value(:smtp_relay) || "",
      username: Config.read_value(:smtp_username) || "",
      password: Config.read_value(:smtp_password) || "",
      subject: Config.read_value(:smtp_subject) || "NSG LoRa",
      sender: Config.read_value(:smtp_sender) || "",
      receiver: Config.read_value(:smtp_receiver) || ""
    }
  end

  defp smtp(server, sender, receiver_list, subject, text) do
    :gen_smtp_client.send(
      {sender, receiver_list,
       "Content-Type: text/plain; charset=utf-8\r\n" <>
         "Subject: #{subject}\r\n" <>
         "From: #{sender}\r\n" <>
         "To: #{receiver_list |> Enum.join(",")}\r\n\r\n" <>
         "#{text}"},
      server ++
        [
          auth: 'always',
          tls: 'always',
          ssl: true
        ],
      fn
        res ->
          IO.inspect(res, label: "SMTP RES")
          'ok'
      end
    )

    text
  end

  def send_email() do
    smtp(
      [
        relay: 'mail.nsg.net.ru',
        username: 'imosunov',
        password: 'baidnos0'
      ],
      "imosunov@nsg.net.ru",
      ["imo59y@yandex.ru"],
      "LoRa",
      "Test"
    )
  end
end
