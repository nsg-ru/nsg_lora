defmodule NsgLoraWeb.RootLive do
  use NsgLoraWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # TODO read real admin
    lang = get_lang("admin")
    Gettext.put_locale(lang)

    {:ok, admin} = NsgLora.Repo.Admin.read("admin")
    opts = admin.opts || %{}
    menu_item = opts[:menu_item] || "dashboard"

    {:ok,
     assign(socket,
       lang: lang,
       menu_item: menu_item
     )}
  end

  @impl true
  def handle_event("toggle-lang", _params, socket) do
    get_lang("admin", toggle: true)

    {:noreply,
     push_redirect(socket,
       to: Routes.live_path(socket, NsgLoraWeb.RootLive)
     )}
  end

  def handle_event("menu-item", %{"name" => name}, socket) do
    {:ok, admin} = NsgLora.Repo.Admin.read("admin")
    opts = admin.opts || %{}
    opts = Map.put(opts, :menu_item, name)
    NsgLora.Repo.Admin.write(%{admin | opts: opts})

    {:noreply, assign(socket, menu_item: name)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(%{event: event, params: params})
    {:noreply, socket}
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    {:noreply, assign(socket, uri: URI.parse(uri))}
  end

  defp get_lang(admin, opts \\ []) do
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
