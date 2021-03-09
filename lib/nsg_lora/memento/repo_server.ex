defmodule NsgLora.Repo.Server do
  use Memento.Table,
    attributes: [:sname, :name, :adm_state, :config, :opts]

  def all() do
    Memento.transaction(fn -> Memento.Query.all(__MODULE__) end)
  end

  def read(sname) do
    Memento.transaction(fn -> Memento.Query.read(__MODULE__, sname) end)
  end

  def write(server = %__MODULE__{}) do
    NsgLora.Repo.write(server)
  end

  def write(server = %{}) do
    struct = %__MODULE__{
      sname: server[:sname],
      name: server[:name],
      adm_state: server[:adm_state],
      config: server[:config],
      opts: server[:opts]
    }

    NsgLora.Repo.write(struct)
  end

  def delete(username) do
    Memento.transaction(fn -> Memento.Query.delete(__MODULE__, username) end)
  end

end
