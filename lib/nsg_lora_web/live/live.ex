defmodule NsgLoraWeb.Live do
  alias NsgLoraWeb.Router.Helpers, as: Routes
  use Phoenix.LiveView

  def init(mod, session, socket) do
    path = Routes.live_path(socket, mod)
    id = session["current_admin"]
    {:ok, admin} = NsgLora.Repo.Admin.read(id)

    opts = admin.opts || %{}
    lang = opts[:lang] || "ru"
    Gettext.put_locale(lang)

    %{
      path: path,
      admin: %{admin | opts: Map.put(opts, :lang, lang)},
      alert: %{hidden: true, text: ""}
    }
  end

end
