defmodule NsgLoraWeb.PageController do
  use NsgLoraWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def login(conn, _) do
    conn
    |> redirect(to: Routes.live_path(conn, NsgLoraWeb.DashboardLive))
  end

end
