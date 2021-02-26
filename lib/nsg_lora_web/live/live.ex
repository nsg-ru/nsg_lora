defmodule NsgLoraWeb.Live do
  alias NsgLoraWeb.Router.Helpers, as: Routes

  def init(mod, session, socket) do
    path = Routes.live_path(socket, mod)
    id = session["current_admin"]
    lang = get_lang(id)

    Gettext.put_locale(lang)

    [
      path: path,
      admin: id,
      lang: lang
    ]
  end

  def get_lang(admin, opts \\ []) do
    toggle = opts[:toggle]
    {:ok, admin} = NsgLora.Repo.Admin.read(admin)
    opts = admin.opts || %{}

    {lang, update} =
      case opts[:lang] do
        "ru" -> {(toggle && "en") || "ru", false}
        "en" -> {(toggle && "ru") || "en", false}
        _ -> {"ru", true}
      end

    if toggle || update do
      opts = Map.put(opts, :lang, lang)
      NsgLora.Repo.Admin.write(%{admin | opts: opts})
    end

    lang
  end
end
