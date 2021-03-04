defmodule NsgLora.DBServer do
  use GenServer
  require Logger

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  @impl true
  def init(_params) do
    nodes = [node() | Node.list()]

    if !Memento.system()[:use_dir] do
      Memento.stop()
      Memento.Schema.create(nodes)
    end

    Memento.start()

    # # if cluster problems
    # :mnesia.system_info(:tables)
    # |> Enum.each(fn t -> :mnesia.force_load_table(t) end)

    Memento.Table.create(NsgLora.Repo.Admin, disc_copies: nodes)

    case NsgLora.Repo.Admin.all() do
      {:ok, []} -> NsgLora.Repo.Admin.write(%{"username" => "admin", "password" => "admin"})
      _ -> nil
    end

    Application.ensure_all_started(:lorawan_server)


    {:ok, %{}}
  end
end
