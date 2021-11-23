defmodule NsgLora.RepoTest do
  use ExUnit.Case

  test "validate hex" do
    key = "temporary_key"

    assert NsgLora.Repo.Config.write(key, "value") ==
             {:ok,
              %NsgLora.Repo.Config{__meta__: Memento.Table, key: "temporary_key", value: "value"}}

    assert NsgLora.Repo.Config.read(key) ==
             {:ok,
              %NsgLora.Repo.Config{__meta__: Memento.Table, key: "temporary_key", value: "value"}}

    assert NsgLora.Repo.Config.read_value(key) == "value"
    assert NsgLora.Repo.Config.delete(key) == :ok
    assert NsgLora.Repo.Config.read(key) == {:ok, nil}
    assert NsgLora.Repo.Config.read_value(key) == nil
  end
end
