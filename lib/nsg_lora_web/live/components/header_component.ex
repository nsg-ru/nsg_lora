defmodule NsgLoraWeb.HeaderComponent do
  use NsgLoraWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("toggle-lang", _params, socket) do
    toggle_lang(socket.assigns.admin.username)

    {:noreply, push_redirect(socket, to: socket.assigns.path)}
  end

  def handle_event("toggle-theme", _params, socket) do
    admin = toggle_theme(socket.assigns.admin.username)

    {:noreply, assign(socket, admin: admin)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params, assigns: socket.assigns)
    {:noreply, socket}
  end

  def toggle_lang(username) do
    {:ok, admin} = NsgLora.Repo.Admin.read(username)
    opts = admin.opts || %{}

    lang =
      case opts[:lang] do
        "en" -> "ru"
        _ -> "en"
      end

    opts = Map.put(opts, :lang, lang)
    NsgLora.Repo.Admin.write(%{admin | opts: opts})
  end

  def toggle_theme(username) do
    {:ok, admin} = NsgLora.Repo.Admin.read(username)
    opts = admin.opts || %{}

    theme =
      case opts[:light_theme] do
        true -> false
        _ -> true
      end

    opts = Map.put(opts, :light_theme, theme)
    admin = %{admin | opts: opts}
    NsgLora.Repo.Admin.write(admin)
    admin
  end
end