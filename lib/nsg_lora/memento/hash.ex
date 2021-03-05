defmodule NsgLora.Hash do
  def hash_pwd_salt(password) do
    :crypto.hash(:sha3_512, password)
  end

  def verify_pass(password, hash) do
    hash == :crypto.hash(:sha3_512, password)
  end

  def no_user_verify() do
    false
  end
end
