defmodule MangoCMS.Tenant.Accounts.UserToken do
  use Ecto.Schema

  import Ecto.Query

  alias MangoCMS.Tenant.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @session_context "session"
  @confirm_context "confirm"
  @reset_password_context "reset_password"
  @session_validity_in_days 60
  @confirm_validity_in_days 7
  @reset_password_validity_in_hours 24

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    belongs_to :user, User

    timestamps(updated_at: false)
  end

  def build_session_token(%User{} = user), do: build_token(user, @session_context)
  def build_confirmation_token(%User{} = user), do: build_token(user, @confirm_context)
  def build_reset_password_token(%User{} = user), do: build_token(user, @reset_password_context)

  def verify_session_token_query(token) do
    hashed_token = token |> Base.url_decode64!(padding: false) |> hash_token()

    from token in by_token_and_context_query(hashed_token, @session_context),
      join: user in assoc(token, :user),
      where: token.inserted_at > ago(@session_validity_in_days, "day"),
      select: user
  end

  def verify_confirmation_token_query(token) do
    verify_token_query(token, @confirm_context, @confirm_validity_in_days, "day")
  end

  def verify_reset_password_token_query(token) do
    verify_token_query(token, @reset_password_context, @reset_password_validity_in_hours, "hour")
  end

  def delete_session_token_query(token) do
    hashed_token = token |> Base.url_decode64!(padding: false) |> hash_token()
    by_token_and_context_query(hashed_token, @session_context)
  end

  def user_context_query(%User{id: user_id}, context) do
    from __MODULE__, where: [user_id: ^user_id, context: ^context]
  end

  def confirmation_context, do: @confirm_context
  def reset_password_context, do: @reset_password_context

  defp build_token(%User{} = user, context) do
    token = :crypto.strong_rand_bytes(32)
    hashed_token = hash_token(token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{token: hashed_token, context: context, user_id: user.id}}
  end

  defp verify_token_query(token, context, amount, "day") do
    hashed_token = token |> Base.url_decode64!(padding: false) |> hash_token()

    from token in by_token_and_context_query(hashed_token, context),
      join: user in assoc(token, :user),
      where: token.inserted_at > ago(^amount, "day"),
      select: user
  end

  defp verify_token_query(token, context, amount, "hour") do
    hashed_token = token |> Base.url_decode64!(padding: false) |> hash_token()

    from token in by_token_and_context_query(hashed_token, context),
      join: user in assoc(token, :user),
      where: token.inserted_at > ago(^amount, "hour"),
      select: user
  end

  defp by_token_and_context_query(token, context) do
    from __MODULE__, where: [token: ^token, context: ^context]
  end

  defp hash_token(token), do: :crypto.hash(:sha256, token)
end
