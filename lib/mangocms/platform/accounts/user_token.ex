defmodule MangoCMS.Platform.Accounts.UserToken do
  use Ecto.Schema

  import Ecto.Query

  alias MangoCMS.Platform.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @session_context "session"
  @session_validity_in_days 60

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    belongs_to :user, User

    timestamps(updated_at: false)
  end

  def build_session_token(%User{} = user) do
    token = :crypto.strong_rand_bytes(32)
    hashed_token = hash_token(token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{token: hashed_token, context: @session_context, user_id: user.id}}
  end

  def verify_session_token_query(token) do
    hashed_token = token |> Base.url_decode64!(padding: false) |> hash_token()

    from token in by_token_and_context_query(hashed_token, @session_context),
      join: user in assoc(token, :user),
      where: token.inserted_at > ago(@session_validity_in_days, "day"),
      select: user
  end

  def delete_session_token_query(token) do
    hashed_token = token |> Base.url_decode64!(padding: false) |> hash_token()
    by_token_and_context_query(hashed_token, @session_context)
  end

  defp by_token_and_context_query(token, context) do
    from __MODULE__, where: [token: ^token, context: ^context]
  end

  defp hash_token(token), do: :crypto.hash(:sha256, token)
end
