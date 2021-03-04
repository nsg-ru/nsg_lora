defmodule NsgLora.ErrorHandler do
  alias NsgLoraWeb.Router.Helpers, as: Routes

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> Phoenix.Controller.redirect(to: Routes.session_path(conn, :new))
  end
end
