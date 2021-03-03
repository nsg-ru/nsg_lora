defmodule NsgLora.Repo do
  def write(struct) do
    Memento.transaction(fn ->
      try do
        Memento.Query.write(struct)
      rescue
        err in Memento.Error -> Memento.Transaction.abort(err.message)
        res -> Memento.Transaction.abort(inspect(res))
      end
    end)
  end
end

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
    NsgLora.Repo.write(admin)
  end

  def write(admin = %{}) do
    admin_struct = %__MODULE__{
      username: (if admin["username"] == "", do: nil, else: admin["username"]),
      fullname: admin["fullname"],
      hash: admin["hash"],
      opts: admin["opts"]
    }
    NsgLora.Repo.write(admin_struct)
  end

  def delete(username) do
    Memento.transaction(fn -> Memento.Query.delete(__MODULE__, username) end)
  end

  def load_current_admin(conn, _) do
    conn
    |> Plug.Conn.put_session("current_admin", "admin")
  end
end
