defmodule NsgLora.Guardian do
  use Guardian, otp_app: :nsg_lora

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.username)}
  end

  def resource_from_claims(%{"sub" => id}) do
    user = NsgLora.Repo.Admin.read(id)
    {:ok, user}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end
end
