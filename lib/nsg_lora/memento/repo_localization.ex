defmodule NsgLora.Repo.Localization do
  use Memento.Table,
    attributes: [:id, :coord, :rssi],
    type: :ordered_set,
    autoincrement: true

  def all() do
    Memento.transaction(fn -> Memento.Query.all(__MODULE__) end)
  end

  def write(fp = %__MODULE__{}) do
    NsgLora.Repo.write(fp)
  end

  def write(fp = %{}) do
    NsgLora.Repo.write(struct(NsgLora.Repo.Localization, fp))
  end

  def delete(id) do
    Memento.transaction(fn -> Memento.Query.delete(__MODULE__, id) end)
  end
end
