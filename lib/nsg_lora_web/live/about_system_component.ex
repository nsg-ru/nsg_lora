defmodule NsgLoraWeb.AboutSystemComponent do
  use Phoenix.LiveComponent
  import NsgLoraWeb.Gettext

  @impl true
  def update(_assigns, socket) do
    if connected?(socket) do
      #Process.send_after(self(), :timer, 1000)
    end

    {top, 0} = System.cmd("top", ["-bn1"])
    {cpu, 0} = System.cmd("cat", ["/proc/cpuinfo"])
    {:ok, assign(socket, top: top, cpu: cpu)}
  end

  @impl true
  def handle_info(:timer, socket) do
    Process.send_after(self(), :timer, 2000)
    {top, 0} = System.cmd("top", ["-bn1"])
    {:noreply, assign(socket, top: top)}
  end
end
