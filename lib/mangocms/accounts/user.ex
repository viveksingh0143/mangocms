defmodule MangoCMS.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Accounts.Password
  alias MangoCMS.Platform.Tenant

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @scopes ~w(platform tenant)
  @roles ~w(admin owner editor viewer)

  @type t :: %__MODULE__{}

  schema "users" do
    belongs_to :tenant, Tenant

    field :scope, :string
    field :identity_key, :string
    field :email, :string
    field :hashed_password, :string, redact: true
    field :password, :string, virtual: true, redact: true
    field :full_name, :string
    field :phone, :string
    field :avatar_url, :string
    field :locale, :string, default: "en"
    field :timezone, :string, default: "UTC"
    field :role, :string, default: "admin"
    field :confirmed_at, :utc_datetime
    field :disabled_at, :utc_datetime

    timestamps()
  end

  def registration_changeset(user, attrs, opts) do
    user
    |> cast(attrs, [:email, :password, :full_name, :phone, :locale, :timezone])
    |> put_scope(opts)
    |> validate_email()
    |> validate_password()
    |> validate_profile()
    |> put_identity_key()
    |> put_password_hash()
    |> put_change(:confirmed_at, DateTime.utc_now(:second))
    |> validate_required([:scope, :identity_key])
    |> unique_constraint(:identity_key)
  end

  def sso_changeset(user, attrs, opts) do
    user
    |> cast(attrs, [:email, :full_name, :avatar_url])
    |> put_scope(opts)
    |> validate_email()
    |> validate_profile()
    |> put_identity_key()
    |> put_change(:confirmed_at, DateTime.utc_now(:second))
    |> validate_required([:scope, :identity_key])
    |> unique_constraint(:identity_key)
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :full_name, :phone, :avatar_url, :locale, :timezone])
    |> validate_email()
    |> validate_profile()
    |> put_identity_key()
    |> unique_constraint(:identity_key)
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_password()
    |> put_password_hash()
  end

  def disabled?(%__MODULE__{disabled_at: nil}), do: false
  def disabled?(%__MODULE__{}), do: true

  def platform?(%__MODULE__{scope: "platform", tenant_id: nil}), do: true
  def platform?(_), do: false

  def tenant?(%__MODULE__{scope: "tenant", tenant_id: tenant_id}, tenant_id)
      when is_binary(tenant_id),
      do: true

  def tenant?(_, _), do: false

  def identity_key("platform", nil, email), do: "platform:#{normalize_email(email)}"

  def identity_key("tenant", tenant_id, email),
    do: "tenant:#{tenant_id}:#{normalize_email(email)}"

  def normalize_email(email) when is_binary(email) do
    email
    |> String.trim()
    |> String.downcase()
  end

  def normalize_email(email), do: email

  defp put_scope(changeset, opts) do
    scope = Keyword.fetch!(opts, :scope)
    tenant_id = Keyword.get(opts, :tenant_id)

    changeset
    |> put_change(:scope, scope)
    |> put_change(:tenant_id, tenant_id)
    |> validate_inclusion(:scope, @scopes)
    |> validate_required(scope_required_fields(scope))
  end

  defp scope_required_fields("platform"), do: [:scope]
  defp scope_required_fields("tenant"), do: [:scope, :tenant_id]
  defp scope_required_fields(_), do: [:scope]

  defp validate_email(changeset) do
    changeset
    |> update_change(:email, &normalize_email/1)
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
  end

  defp validate_profile(changeset) do
    changeset
    |> validate_length(:full_name, max: 120)
    |> validate_length(:phone, max: 40)
    |> validate_length(:avatar_url, max: 500)
    |> validate_length(:locale, max: 20)
    |> validate_length(:timezone, max: 80)
    |> validate_inclusion(:role, @roles)
  end

  defp put_identity_key(changeset) do
    scope = get_field(changeset, :scope)
    tenant_id = get_field(changeset, :tenant_id)
    email = get_field(changeset, :email)

    if scope in @scopes and is_binary(email) do
      put_change(changeset, :identity_key, identity_key(scope, tenant_id, email))
    else
      changeset
    end
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    put_change(changeset, :hashed_password, Password.hash(password))
  end

  defp put_password_hash(changeset), do: changeset
end
