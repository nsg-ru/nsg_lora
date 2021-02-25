defmodule NsgLora.Repo.Admin do
  use Memento.Table,
    attributes: [:username, :fullname, :hash, :opts]

  def all() do
    Memento.transaction(fn -> Memento.Query.all(__MODULE__) end)
  end

  def read(username) do
    Memento.transaction(fn -> Memento.Query.read(__MODULE__, username) end)
  end

  def write(admin = %NsgLora.Repo.Admin{}) do
    Memento.transaction(fn -> Memento.Query.write(admin) end)
  end

  def write(admin = %{}) do
    admin_struct = %__MODULE__{
      username: admin[:username],
      fullname: admin[:fullname],
      hash: admin[:hash],
      opts: admin[:opts]
    }

    Memento.transaction(fn -> Memento.Query.write(admin_struct) end)
  end
end
