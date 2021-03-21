defmodule NsgLora.LoraWan do
  require Record

  Record.defrecord(
    :user,
    Record.extract(:user, from: "deps/lorawan_server/include/lorawan.hrl")
  )
end
