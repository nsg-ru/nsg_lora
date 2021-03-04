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
    hash = Argon2.hash_pwd_salt(admin["password"])

    admin_struct = %__MODULE__{
      username: admin["username"],
      fullname: admin["fullname"],
      hash: hash,
      opts: admin["opts"]
    }

    NsgLora.Repo.write(admin_struct)
  end

  def delete(username) do
    Memento.transaction(fn -> Memento.Query.delete(__MODULE__, username) end)
  end

  def authenticate(username, plain_text_password) do
    case read(username) do
      {:ok, admin = %NsgLora.Repo.Admin{hash: hash}} when is_binary(hash) ->
        if Argon2.verify_pass(plain_text_password, hash) do
          {:ok, admin}
        else
          {:error, :invalid_credentials}
        end

      _ ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def load_current_admin(conn, _) do
    conn
    |> Plug.Conn.put_session("current_admin", "admin")
  end
end
