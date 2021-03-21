defmodule NsgLora.Repo.Admin do
  use Memento.Table,
    attributes: [:username, :fullname, :hash, :opts]

  require NsgLora.LoraWan

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
    hash = NsgLora.Hash.hash_pwd_salt(admin["password"])

    admin_struct = %__MODULE__{
      username: admin["username"],
      fullname: admin["fullname"],
      hash: hash,
      opts: admin["opts"]
    }

    set_lorawan_server_user(admin_struct.username, admin["password"])
    NsgLora.Repo.write(admin_struct)
  end

  def update(username, params) do
    {:ok, admin} = read(username)

    hash =
      case params["password"] do
        "" ->
          admin.hash

        _ ->
          set_lorawan_server_user(admin.username, params["password"])
          NsgLora.Hash.hash_pwd_salt(params["password"])
      end

    admin = %{admin | fullname: params["fullname"], hash: hash}
    write(admin)
  end

  def delete(username) do
    :mnesia.dirty_delete(:user, username)
    Memento.transaction(fn -> Memento.Query.delete(__MODULE__, username) end)
  end

  def authenticate(username, plain_text_password) do
    case read(username) do
      {:ok, admin = %NsgLora.Repo.Admin{hash: hash}} when is_binary(hash) ->
        if NsgLora.Hash.verify_pass(plain_text_password, hash) do
          {:ok, admin}
        else
          {:error, :invalid_credentials}
        end

      _ ->
        NsgLora.Hash.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def load_current_admin(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      {:ok, %{username: name}} ->
        conn
        |> Plug.Conn.put_session("current_admin", name)

      _ ->
        conn
    end
  end

  @realm "lorawan-server"
  def set_lorawan_server_user(name, password) do
    :mnesia.transaction(fn ->
      :mnesia.write(
        NsgLora.LoraWan.user(
          name: name,
          pass_ha1: :lorawan_http_digest.ha1({name, @realm, password})
        )
      )
    end)
  end
end
