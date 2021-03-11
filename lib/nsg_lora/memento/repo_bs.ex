defmodule NsgLora.Repo.BS do
  use Memento.Table,
    attributes: [:sname, :adm_state, :phy, :gw, :opts]

  def all() do
    Memento.transaction(fn -> Memento.Query.all(__MODULE__) end)
  end

  def read(sname) do
    Memento.transaction(fn -> Memento.Query.read(__MODULE__, sname) end)
  end

  def write(bs = %__MODULE__{}) do
    NsgLora.Repo.write(bs)
  end

  def write(bs = %{}) do
    NsgLora.Repo.write(struct(NsgLora.Repo.BS, bs))
  end

  def delete(username) do
    Memento.transaction(fn -> Memento.Query.delete(__MODULE__, username) end)
  end

end
