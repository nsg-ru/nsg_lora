defmodule NsgLora.ValidateTest do
  use ExUnit.Case

  setup do
    {:ok, locale: Gettext.put_locale("en")}
  end

  test "validate hex" do
    assert NsgLora.Validate.hex(%{}, :key, "09aF", 4) == %{}
    assert NsgLora.Validate.hex(%{}, :key, "09aF", 3) == %{key: "Must be 3 chars"}
    assert NsgLora.Validate.hex(%{}, :key, "09aF") == %{}
    assert NsgLora.Validate.hex(%{}, :key, "09aX") == %{key: "Must be hex number"}
  end
end
