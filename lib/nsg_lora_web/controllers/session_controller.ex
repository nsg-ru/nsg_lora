defmodule NsgLoraWeb.SessionController do
  use NsgLoraWeb, :controller

  alias NsgLora.{Repo.Admin, Guardian}

  def new(conn, _) do
    maybe_user = Guardian.Plug.current_resource(conn)

    if maybe_user do
      redirect(conn, to: Routes.live_path(conn, NsgLoraWeb.DashboardLive))
    else
      render(conn, "new.html", action: Routes.session_path(conn, :login))
    end
  end

  def login(conn, %{"name" => username, "password" => password}) do
    Admin.authenticate(username, password)
    |> login_reply(conn)
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: "/login")
  end

  defp login_reply({:ok, user}, conn) do
    conn
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: Routes.live_path(conn, NsgLoraWeb.DashboardLive))
  end

  defp login_reply({:error, _reason}, conn) do
    conn
    |> put_flash(:error, gettext("Bad password"))
    |> new(%{})
  end
end
