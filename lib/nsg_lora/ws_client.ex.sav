defmodule NsgLora.WsClient do
  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{})
  end

  def handle_frame({type, msg}, state) do
    IO.puts "Received Message - Type: #{inspect type} -- Message: #{inspect msg}"
    {:ok, state}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts "Sending #{type} frame with payload: #{msg}"
    {:reply, frame, state}
  end

  def start_child(url) do
    DynamicSupervisor.start_child(
      NsgLora.DynSup,
      {__MODULE__, url}
    )
  end
end
