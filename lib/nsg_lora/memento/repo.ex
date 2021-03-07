defmodule NsgLora.Repo do
  def write(struct) do
    Memento.transaction(fn ->
      try do
        Memento.Query.write(struct)
      rescue
        err in Memento.Error -> Memento.Transaction.abort(err.message)
        res -> Memento.Transaction.abort(inspect(res))
      end
    end)
  end
end
