defmodule MangoCMS.TenantAccounts do
  @moduledoc "Tenant-local users, sessions, password reset, and email verification."

  import Ecto.Changeset

  alias MangoCMS.Accounts.Password
  alias MangoCMS.Platform.Tenant
  alias MangoCMS.TenantAccounts.{User, UserNotifier, UserToken}
  alias MangoCMS.TenantRepoManager

  def change_admin_registration(attrs \\ %{}) do
    change_registration(attrs, role: "admin")
  end

  def change_member_registration(attrs \\ %{}) do
    change_registration(attrs, role: "member")
  end

  def change_owner_registration(attrs \\ %{}) do
    change_registration(attrs, role: "owner")
  end

  def register_admin_user(%Tenant{} = tenant, attrs), do: register_user(tenant, attrs, "admin")
  def register_member_user(%Tenant{} = tenant, attrs), do: register_user(tenant, attrs, "member")
  def register_owner_user(%Tenant{} = tenant, attrs), do: register_user(tenant, attrs, "owner")

  def authenticate_admin_user(%Tenant{} = tenant, email, password) do
    with {:ok, %User{} = user} <- authenticate_user(tenant, email, password),
         true <- User.admin_role?(user) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  def authenticate_user(%Tenant{} = tenant, email, password) do
    with %User{} = user <- get_user_by_email(tenant, email),
         false <- User.disabled?(user),
         true <- Password.verify(password, user.hashed_password) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  def get_user!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, & &1.get!(User, id))
  end

  def get_user_by_email(%Tenant{} = tenant, email) do
    identity_key = User.identity_key(email)
    TenantRepoManager.with_repo(tenant, & &1.get_by(User, identity_key: identity_key))
  end

  def get_user_by_session_token(%Tenant{} = _tenant, nil), do: nil

  def get_user_by_session_token(%Tenant{} = tenant, token) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      token
      |> UserToken.verify_session_token_query()
      |> repo.one()
    end)
  rescue
    ArgumentError -> nil
  end

  def generate_user_session_token(%Tenant{} = tenant, %User{} = user) do
    {token, user_token} = UserToken.build_session_token(user)
    TenantRepoManager.with_repo(tenant, & &1.insert!(user_token))
    token
  end

  def delete_user_session_token(%Tenant{} = _tenant, nil), do: :ok

  def delete_user_session_token(%Tenant{} = tenant, token) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      token
      |> UserToken.delete_session_token_query()
      |> repo.delete_all()
    end)

    :ok
  rescue
    ArgumentError -> :ok
  end

  def change_user_profile(%User{} = user, attrs \\ %{}), do: User.profile_changeset(user, attrs)
  def change_user_password(%User{} = user, attrs \\ %{}), do: User.password_changeset(user, attrs)

  def update_user_profile(%Tenant{} = tenant, %User{} = user, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      user
      |> User.profile_changeset(attrs)
      |> repo.update()
    end)
  end

  def update_user_password(%Tenant{} = tenant, %User{} = user, current_password, attrs) do
    if Password.verify(current_password, user.hashed_password) do
      TenantRepoManager.with_repo(tenant, fn repo ->
        user
        |> User.password_changeset(attrs)
        |> repo.update()
      end)
    else
      changeset =
        user
        |> User.password_changeset(attrs)
        |> add_error(:current_password, "is not valid")

      {:error, changeset}
    end
  end

  def generate_confirmation_token(%Tenant{} = tenant, %User{} = user) do
    {token, user_token} = UserToken.build_confirmation_token(user)
    replace_user_token!(tenant, user, UserToken.confirmation_context(), user_token)
    token
  end

  def deliver_confirmation_instructions(%Tenant{} = tenant, %User{} = user, url_fun)
      when is_function(url_fun, 1) do
    token = generate_confirmation_token(tenant, user)
    UserNotifier.deliver_confirmation_instructions(user, url_fun.(token))
  end

  def confirm_user(%Tenant{} = tenant, token) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      case repo.one(UserToken.verify_confirmation_token_query(token)) do
        %User{} = user ->
          user
          |> User.confirm_changeset()
          |> repo.update()

        nil ->
          :error
      end
    end)
  rescue
    ArgumentError -> :error
  end

  def generate_reset_password_token(%Tenant{} = tenant, %User{} = user) do
    {token, user_token} = UserToken.build_reset_password_token(user)
    replace_user_token!(tenant, user, UserToken.reset_password_context(), user_token)
    token
  end

  def deliver_reset_password_instructions(%Tenant{} = tenant, email, url_fun)
      when is_function(url_fun, 1) do
    case get_user_by_email(tenant, email) do
      %User{} = user ->
        token = generate_reset_password_token(tenant, user)
        UserNotifier.deliver_reset_password_instructions(user, url_fun.(token))

      nil ->
        {:ok, nil}
    end
  end

  def reset_user_password(%Tenant{} = tenant, token, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      case repo.one(UserToken.verify_reset_password_token_query(token)) do
        %User{} = user ->
          result =
            user
            |> User.password_changeset(attrs)
            |> repo.update()

          if match?({:ok, _user}, result) do
            repo.delete_all(
              UserToken.user_context_query(user, UserToken.reset_password_context())
            )
          end

          result

        nil ->
          :error
      end
    end)
  rescue
    ArgumentError -> :error
  end

  def admin_user?(%User{} = user), do: User.admin_role?(user) and not User.disabled?(user)
  def admin_user?(_), do: false

  def active_user?(%User{} = user), do: not User.disabled?(user)
  def active_user?(_), do: false

  defp change_registration(attrs, opts) do
    %User{}
    |> User.registration_changeset(attrs, opts)
    |> Map.put(:action, nil)
  end

  defp register_user(%Tenant{} = tenant, attrs, role) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %User{}
      |> User.registration_changeset(attrs, role: role)
      |> repo.insert()
    end)
  end

  defp replace_user_token!(%Tenant{} = tenant, %User{} = user, context, user_token) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.delete_all(UserToken.user_context_query(user, context))
      repo.insert!(user_token)
    end)
  end
end
