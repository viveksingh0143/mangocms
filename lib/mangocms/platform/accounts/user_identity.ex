defmodule MangoCMS.Platform.Accounts.UserIdentity do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Platform.Accounts.User
  alias MangoCMS.Platform.Tenant

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @providers ~w(google outlook apple)
  @scopes ~w(platform tenant)

  schema "user_identities" do
    belongs_to :user, User
    belongs_to :tenant, Tenant

    field :scope, :string
    field :provider, :string
    field :provider_uid, :string
    field :identity_key, :string
    field :email, :string
    field :name, :string
    field :avatar_url, :string
    field :raw_data, :map, default: %{}

    timestamps()
  end

  def changeset(identity, attrs, opts) do
    identity
    |> cast(attrs, [:provider, :provider_uid, :email, :name, :avatar_url, :raw_data, :user_id])
    |> put_scope(opts)
    |> validate_required([:user_id, :scope, :provider, :provider_uid])
    |> validate_inclusion(:scope, @scopes)
    |> validate_inclusion(:provider, @providers)
    |> put_identity_key()
    |> validate_required([:identity_key])
    |> unique_constraint(:identity_key)
  end

  def identity_key("platform", nil, provider, provider_uid) do
    "platform:#{provider}:#{provider_uid}"
  end

  def identity_key("tenant", tenant_id, provider, provider_uid) do
    "tenant:#{tenant_id}:#{provider}:#{provider_uid}"
  end

  defp put_scope(changeset, opts) do
    changeset
    |> put_change(:scope, Keyword.fetch!(opts, :scope))
    |> put_change(:tenant_id, Keyword.get(opts, :tenant_id))
  end

  defp put_identity_key(changeset) do
    scope = get_field(changeset, :scope)
    tenant_id = get_field(changeset, :tenant_id)
    provider = get_field(changeset, :provider)
    provider_uid = get_field(changeset, :provider_uid)

    if scope in @scopes and provider in @providers and is_binary(provider_uid) do
      put_change(changeset, :identity_key, identity_key(scope, tenant_id, provider, provider_uid))
    else
      changeset
    end
  end
end
