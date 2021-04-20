defmodule NsgLoraWeb.AboutSystemLive do
  use NsgLoraWeb, :live_view
  # import NsgLoraWeb.Gettext

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    {top, 0} = System.cmd("top", ["-bn1"])
    {cpu, 0} = System.cmd("cat", ["/proc/cpuinfo"])
    # Process.send_after(self(), :timer, 1000)
    {:ok, assign(socket, top: top, cpu: cpu)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:timer, socket) do
    Process.send_after(self(), :timer, 2000)
    {top, 0} = System.cmd("top", ["-bn1"])
    {:noreply, assign(socket, top: top)}
  end
end
