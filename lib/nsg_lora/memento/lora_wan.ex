defmodule NsgLora.LoraWan do
  require Record

  Record.defrecord(
    :user,
    Record.extract(:user, from: "deps/lorawan_server/include/lorawan.hrl")
  )

  Record.defrecord(
    :frame,
    Record.extract(:frame, from: "deps/lorawan_server/include/lorawan.hrl")
  )

  Record.defrecord(
    :rxq,
    Record.extract(:rxq, from: "deps/lorawan_server/include/lorawan_db.hrl")
  )

  Record.defrecord(
    :profile,
    Record.extract(:profile, from: "deps/lorawan_server/include/lorawan_db.hrl")
  )

  Record.defrecord(
    :node,
    Record.extract(:node, from: "deps/lorawan_server/include/lorawan_db.hrl")
  )

  def read() do
    :mnesia.transaction(fn ->
      :mnesia.read(
        NsgLora.LoraWan.node(

        )
      )
    end)
  end

end
