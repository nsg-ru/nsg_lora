defmodule NsgLora.Repo.Config do
  use Memento.Table,
    attributes: [:key, :value]

  def all() do
    Memento.transaction(fn -> Memento.Query.all(__MODULE__) end)
  end

  def read(key) do
    Memento.transaction(fn -> Memento.Query.read(__MODULE__, key) end)
  end

  def read_value(key) do
    case read(key) do
      {:ok, %NsgLora.Repo.Config{key: ^key, value: val}} -> val
      _ -> nil
    end
  end

  def write(config = %NsgLora.Repo.Config{}) do
    NsgLora.Repo.write(config)
  end

  def write(key, value) do
    write(%NsgLora.Repo.Config{key: key, value: value})
  end

  def delete(key) do
    Memento.transaction(fn -> Memento.Query.delete(__MODULE__, key) end)
  end
end
