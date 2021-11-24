defmodule NsgLora.LoraApps.Smtp do
  use GenServer
  require NsgLora.LoraWan

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

    [
      devaddr: frame[:devaddr] |> Base.encode16(),
      data: frame[:data] |> Base.encode16()
    ]
    |> IO.inspect()

    {:noreply, state}
  end

  def rxq(params) do
    GenServer.cast(__MODULE__, {:rxq, params})
  end

  def smtp(%{"deveui" => id}, reciver_list, text) do
    :gen_smtp_client.send(
      {"ileamo@yandex.ru", reciver_list,
       "Content-Type: text/plain; charset=utf-8\r\n" <>
         "Subject: Предупреждение\r\n" <>
         "From: <noreply@nsg.net.ru>\r\n" <>
         "To: #{reciver_list |> Enum.join(",")}\r\n\r\n" <>
         "Датчик #{id}\r\n#{text}"},
      [
        relay: 'mail.nsg.net.ru',
        username: 'imosunov',
        password: 'baidnos0',
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
    smtp(%{"deveui" => "EEEEEE"}, ["imo59y@yandex.ru"], "Test")
  end
end
