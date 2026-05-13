defmodule MangoCMS.Accounts do
  @moduledoc "User accounts, sessions, profile updates, and scoped SSO identities."

  import Ecto.Changeset
  import Ecto.Query

  alias MangoCMS.Accounts.{Password, User, UserIdentity, UserToken}
  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Repo
  alias MangoCMS.TenantAccounts

  def change_registration(attrs \\ %{}, opts) do
    %User{}
    |> User.registration_changeset(attrs, opts)
    |> Map.put(:action, nil)
  end

  def register_platform_user(attrs), do: register_user("platform", nil, attrs, role: "admin")

  def register_platform_customer_user(attrs),
    do: register_user("platform", nil, attrs, role: "customer")

  def register_tenant_user(%Tenant{} = tenant, attrs),
    do: TenantAccounts.register_admin_user(tenant, attrs)

  def authenticate_platform_user(email, password),
    do: authenticate_user("platform", nil, email, password)

  def authenticate_tenant_user(%Tenant{} = tenant, email, password) do
    TenantAccounts.authenticate_admin_user(tenant, email, password)
  end

  def list_users do
    User
    |> order_by([u], desc: u.inserted_at)
    |> Repo.all()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def change_user(%User{} = user, attrs \\ %{}), do: User.management_changeset(user, attrs)

  def create_user(attrs) do
    %User{}
    |> User.management_changeset(attrs, scope: "platform", tenant_id: nil)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.management_changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user), do: Repo.delete(user)

  def get_user_by_session_token(nil), do: nil

  def get_user_by_session_token(token) do
    token
    |> UserToken.verify_session_token_query()
    |> Repo.one()
  rescue
    ArgumentError -> nil
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def delete_user_session_token(nil), do: :ok

  def delete_user_session_token(token) do
    token
    |> UserToken.delete_session_token_query()
    |> Repo.delete_all()

    :ok
  rescue
    ArgumentError -> :ok
  end

  def change_user_profile(%User{} = user, attrs \\ %{}), do: User.profile_changeset(user, attrs)
  def change_user_password(%User{} = user, attrs \\ %{}), do: User.password_changeset(user, attrs)

  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def update_user_password(%User{} = user, current_password, attrs) do
    if Password.verify(current_password, user.hashed_password) do
      user
      |> User.password_changeset(attrs)
      |> Repo.update()
    else
      changeset =
        user
        |> User.password_changeset(attrs)
        |> add_error(:current_password, "is not valid")

      {:error, changeset}
    end
  end

  def upsert_platform_sso_user(provider_profile),
    do: upsert_sso_user("platform", nil, provider_profile)

  def upsert_tenant_sso_user(%Tenant{}, _provider_profile),
    do: {:error, :tenant_sso_not_supported}

  defp register_user(scope, tenant_id, attrs, opts) do
    %User{}
    |> User.registration_changeset(
      attrs,
      Keyword.merge([scope: scope, tenant_id: tenant_id], opts)
    )
    |> Repo.insert()
  end

  defp authenticate_user(scope, tenant_id, email, password) do
    with %User{} = user <- get_user_by_email(scope, tenant_id, email),
         false <- User.disabled?(user),
         true <- Password.verify(password, user.hashed_password) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp get_user_by_email(scope, tenant_id, email) do
    identity_key = User.identity_key(scope, tenant_id, email)
    Repo.get_by(User, identity_key: identity_key)
  end

  defp upsert_sso_user(scope, tenant_id, profile) do
    provider = profile.provider
    provider_uid = profile.provider_uid
    identity_key = UserIdentity.identity_key(scope, tenant_id, provider, provider_uid)

    Repo.transaction(fn ->
      case Repo.get_by(UserIdentity, identity_key: identity_key) do
        %UserIdentity{} = identity ->
          user = Repo.get!(User, identity.user_id)
          update_sso_identity!(identity, profile, scope, tenant_id, user)
          user

        nil ->
          user = find_or_create_sso_user!(scope, tenant_id, profile)
          create_sso_identity!(user, profile, scope, tenant_id)
          user
      end
    end)
    |> case do
      {:ok, user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
    end
  end

  defp find_or_create_sso_user!(scope, tenant_id, profile) do
    email = profile.email || "#{profile.provider_uid}@#{profile.provider}.oauth.local"

    case get_user_by_email(scope, tenant_id, email) do
      %User{} = user ->
        user

      nil ->
        attrs = %{
          email: email,
          full_name: profile.name,
          avatar_url: profile.avatar_url
        }

        %User{}
        |> User.sso_changeset(attrs, scope: scope, tenant_id: tenant_id)
        |> Repo.insert!()
    end
  end

  defp create_sso_identity!(user, profile, scope, tenant_id) do
    %UserIdentity{}
    |> UserIdentity.changeset(Map.put(profile, :user_id, user.id),
      scope: scope,
      tenant_id: tenant_id
    )
    |> Repo.insert!()
  end

  defp update_sso_identity!(identity, profile, scope, tenant_id, user) do
    identity
    |> UserIdentity.changeset(Map.put(profile, :user_id, user.id),
      scope: scope,
      tenant_id: tenant_id
    )
    |> Repo.update!()
  end
end
