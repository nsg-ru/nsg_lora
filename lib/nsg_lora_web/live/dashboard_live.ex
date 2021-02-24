defmodule NsgLoraWeb.DashboardLive do
  use NsgLoraWeb, :live_view

  def mount(params, session, socket) do
    IO.inspect(params, label: "Params")
    IO.inspect(session, label: "Session")
    IO.inspect(socket, label: "Socket")
    Gettext.put_locale("ru")
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end
end
