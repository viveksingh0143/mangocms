defmodule MangoCMS.TenantAccounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Authorization
  alias MangoCMS.Accounts.Password

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  schema "users" do
    field :identity_key, :string
    field :email, :string
    field :hashed_password, :string, redact: true
    field :password, :string, virtual: true, redact: true
    field :full_name, :string
    field :phone, :string
    field :avatar_url, :string
    field :locale, :string, default: "en"
    field :timezone, :string, default: "UTC"
    field :role, :string, default: "member"
    field :confirmed_at, :utc_datetime
    field :disabled_at, :utc_datetime

    timestamps()
  end

  def registration_changeset(user, attrs, opts \\ []) do
    role = Keyword.get(opts, :role, "member")

    user
    |> cast(attrs, [:email, :password, :full_name, :phone, :locale, :timezone])
    |> put_change(:role, role)
    |> validate_email()
    |> validate_password()
    |> validate_profile()
    |> put_identity_key()
    |> put_password_hash()
    |> validate_required([:identity_key, :role])
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

  def management_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :full_name, :phone, :avatar_url, :locale, :timezone, :role])
    |> drop_blank_password()
    |> validate_email()
    |> validate_optional_password()
    |> validate_profile()
    |> put_identity_key()
    |> put_password_hash()
    |> validate_required([:identity_key, :role])
    |> unique_constraint(:identity_key)
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_password()
    |> put_password_hash()
  end

  def confirm_changeset(user) do
    change(user, confirmed_at: DateTime.utc_now(:second))
  end

  def disabled?(%__MODULE__{disabled_at: nil}), do: false
  def disabled?(%__MODULE__{}), do: true

  def admin_role?(%__MODULE__{role: role}), do: Authorization.tenant_admin_role?(role)
  def admin_role?(_), do: false

  def identity_key(email), do: normalize_email(email)

  def normalize_email(email) when is_binary(email) do
    email
    |> String.trim()
    |> String.downcase()
  end

  def normalize_email(email), do: email

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
    |> validate_inclusion(:role, Authorization.tenant_roles())
  end

  defp drop_blank_password(changeset) do
    case get_change(changeset, :password) do
      value when value in ["", nil] -> delete_change(changeset, :password)
      _ -> changeset
    end
  end

  defp validate_optional_password(changeset) do
    cond do
      get_change(changeset, :password) ->
        validate_password(changeset)

      is_nil(get_field(changeset, :hashed_password)) ->
        validate_required(changeset, [:password])

      true ->
        changeset
    end
  end

  defp put_identity_key(changeset) do
    case get_field(changeset, :email) do
      email when is_binary(email) -> put_change(changeset, :identity_key, identity_key(email))
      _ -> changeset
    end
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    put_change(changeset, :hashed_password, Password.hash(password))
  end

  defp put_password_hash(changeset), do: changeset
end
