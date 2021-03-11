defmodule NsgLora.DBServer do
  use GenServer
  require Logger

  @table_list [NsgLora.Repo.Admin, NsgLora.Repo.Server, NsgLora.Repo.BS]

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

    @table_list
    |> Enum.each(fn table ->
      Memento.Table.create(table, disc_copies: nodes)
    end)

    :mnesia.wait_for_tables(@table_list, 5000)

    case NsgLora.Repo.Admin.all() do
      {:ok, []} -> NsgLora.Repo.Admin.write(%{"username" => "admin", "password" => "admin"})
      _ -> nil
    end

    Application.ensure_all_started(:lorawan_server)

    {:ok, %{}}
  end
end
