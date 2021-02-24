defmodule NsgLoraWeb.RootLive do
  use NsgLoraWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    IO.inspect(params, label: "Params")
    IO.inspect(session, label: "Session")
    IO.inspect(socket, label: "Socket")

    IO.inspect(Gettext.get_locale())
    Gettext.put_locale("ru")
    {:ok, assign(socket, lang: "ru")}
  end

  @impl true
  def handle_event("toggle_lang", _params, socket) do
    IO.inspect("lang")
    Gettext.put_locale("en")

    {:noreply,
     push_redirect(socket,
       to: Routes.live_path(socket, NsgLoraWeb.DashboardLive)
     )}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end
end
