defmodule NsgLoraWeb.Live do
  alias NsgLoraWeb.Router.Helpers, as: Routes

  def init(mod, session, socket) do
    path = Routes.live_path(socket, mod)
    id = session["current_admin"]
    {:ok, admin} = NsgLora.Repo.Admin.read(id)

    lang = admin.opts[:lang] || "ru"
    Gettext.put_locale(lang)

    %{
      path: path,
      admin: admin,
    }
  end

end
