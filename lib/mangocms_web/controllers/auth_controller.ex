defmodule MangoCMSWeb.AuthController do
  use MangoCMSWeb, :controller
  import Phoenix.Component, only: [to_form: 1, to_form: 2]

  alias MangoCMS.Accounts
  alias MangoCMS.Accounts.SSO
  alias MangoCMS.TenantAccounts
  alias MangoCMSWeb.UserAuth

  def new(conn, _params) do
    context = auth_context(conn)

    render(conn, :login,
      form: to_form(%{}, as: :user),
      title: auth_title(context, "Sign in"),
      context: context,
      action: login_path(context),
      register_path: register_path(context),
      forgot_password_path: forgot_password_path(context),
      sso_links: sso_links(context)
    )
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    context = auth_context(conn)

    case authenticate(context, email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Signed in successfully.")
        |> UserAuth.log_in_user(user)
        |> redirect(to: admin_home_path(context))

      :error ->
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> render(:login,
          form: to_form(%{"email" => email}, as: :user),
          title: auth_title(context, "Sign in"),
          context: context,
          action: login_path(context),
          register_path: register_path(context),
          forgot_password_path: forgot_password_path(context),
          sso_links: sso_links(context)
        )
    end
  end

  def register(conn, _params) do
    context = auth_context(conn)

    render(conn, :register,
      form: to_form(change_registration(context)),
      title: auth_title(context, registration_title(context)),
      context: context,
      action: register_path(context),
      login_path: login_path(context),
      sso_links: sso_links(context)
    )
  end

  def create_registration(conn, %{"user" => user_params}) do
    context = auth_context(conn)

    case register_user(context, user_params) do
      {:ok, user} ->
        maybe_deliver_confirmation_instructions(conn, context, user)

        conn
        |> put_flash(:info, "Account created successfully.")
        |> UserAuth.log_in_user(user)
        |> redirect(to: admin_home_path(context))

      {:error, changeset} ->
        render(conn, :register,
          form: to_form(changeset),
          title: auth_title(context, registration_title(context)),
          context: context,
          action: register_path(context),
          login_path: login_path(context),
          sso_links: sso_links(context)
        )
    end
  end

  def forgot_password(conn, _params) do
    context = auth_context(conn)

    render(conn, :forgot_password,
      form: to_form(%{}, as: :user),
      title: auth_title(context, "Reset password"),
      context: context,
      action: forgot_password_path(context),
      login_path: login_path(context)
    )
  end

  def send_reset_password(conn, %{"user" => %{"email" => email}}) do
    context = auth_context(conn)
    maybe_deliver_reset_password_instructions(conn, context, email)

    conn
    |> put_flash(:info, "If your email exists, reset instructions will be sent shortly.")
    |> redirect(to: login_path(context))
  end

  def reset_password(conn, %{"token" => token}) do
    context = auth_context(conn)

    render(conn, :reset_password,
      form: to_form(%{}, as: :user),
      title: auth_title(context, "Choose a new password"),
      context: context,
      action: reset_password_path(context, token),
      login_path: login_path(context)
    )
  end

  def update_reset_password(conn, %{"token" => token, "user" => user_params}) do
    context = auth_context(conn)

    case reset_user_password(context, token, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password reset successfully. You can sign in now.")
        |> redirect(to: login_path(context))

      {:error, changeset} ->
        render(conn, :reset_password,
          form: to_form(changeset, as: :user),
          title: auth_title(context, "Choose a new password"),
          context: context,
          action: reset_password_path(context, token),
          login_path: login_path(context)
        )

      :error ->
        conn
        |> put_flash(:error, "Password reset link is invalid or expired.")
        |> redirect(to: forgot_password_path(context))
    end
  end

  def confirm(conn, %{"token" => token}) do
    context = auth_context(conn)

    case confirm_user(context, token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email verified successfully.")
        |> redirect(to: login_path(context))

      :error ->
        conn
        |> put_flash(:error, "Email verification link is invalid or expired.")
        |> redirect(to: login_path(context))
    end
  end

  def edit_profile(conn, _params) do
    context = auth_context(conn)
    user = conn.assigns.current_user

    render(conn, :profile,
      title: auth_title(context, "Profile"),
      context: context,
      user: user,
      profile_form: to_form(change_user_profile(context, user), as: :user),
      password_form: to_form(change_user_password(context, user), as: :user),
      profile_action: profile_path(context),
      password_action: password_path(context),
      back_path: admin_home_path(context)
    )
  end

  def update_profile(conn, %{"user" => user_params}) do
    context = auth_context(conn)
    user = conn.assigns.current_user

    case update_user_profile(context, user, user_params) do
      {:ok, user} ->
        conn
        |> assign(:current_user, user)
        |> put_flash(:info, "Profile updated successfully.")
        |> redirect(to: profile_path(context))

      {:error, changeset} ->
        render(conn, :profile,
          title: auth_title(context, "Profile"),
          context: context,
          user: user,
          profile_form: to_form(changeset, as: :user),
          password_form: to_form(change_user_password(context, user), as: :user),
          profile_action: profile_path(context),
          password_action: password_path(context),
          back_path: admin_home_path(context)
        )
    end
  end

  def update_password(conn, %{"user" => user_params}) do
    context = auth_context(conn)
    user = conn.assigns.current_user
    current_password = Map.get(user_params, "current_password", "")

    case update_user_password(context, user, current_password, user_params) do
      {:ok, user} ->
        conn
        |> assign(:current_user, user)
        |> put_flash(:info, "Password updated successfully.")
        |> redirect(to: profile_path(context))

      {:error, changeset} ->
        render(conn, :profile,
          title: auth_title(context, "Profile"),
          context: context,
          user: user,
          profile_form: to_form(change_user_profile(context, user), as: :user),
          password_form: to_form(changeset, as: :user),
          profile_action: profile_path(context),
          password_action: password_path(context),
          back_path: admin_home_path(context)
        )
    end
  end

  def delete(conn, _params) do
    context = auth_context(conn)

    conn
    |> put_flash(:info, "Signed out successfully.")
    |> UserAuth.log_out_user()
    |> redirect(to: login_path(context))
  end

  defp auth_context(conn) do
    cond do
      String.starts_with?(conn.request_path, "/platform/admin") ->
        :platform

      String.starts_with?(conn.request_path, "/admin") ->
        {:tenant_admin, conn.assigns.current_tenant}

      true ->
        {:tenant_member, conn.assigns.current_tenant}
    end
  end

  defp authenticate(:platform, email, password),
    do: Accounts.authenticate_platform_user(email, password)

  defp authenticate({:tenant_admin, tenant}, email, password) do
    TenantAccounts.authenticate_admin_user(tenant, email, password)
  end

  defp authenticate({:tenant_member, tenant}, email, password) do
    TenantAccounts.authenticate_user(tenant, email, password)
  end

  defp register_user(:platform, params), do: Accounts.register_platform_user(params)

  defp register_user({:tenant_admin, tenant}, params) do
    TenantAccounts.register_admin_user(tenant, params)
  end

  defp register_user({:tenant_member, tenant}, params) do
    TenantAccounts.register_member_user(tenant, params)
  end

  defp maybe_deliver_confirmation_instructions(conn, {_tenant_context, tenant} = context, user) do
    TenantAccounts.deliver_confirmation_instructions(tenant, user, fn token ->
      absolute_url(conn, confirm_path(context, token))
    end)

    :ok
  end

  defp maybe_deliver_confirmation_instructions(_conn, :platform, _user), do: :ok

  defp maybe_deliver_reset_password_instructions(conn, {_tenant_context, tenant} = context, email) do
    TenantAccounts.deliver_reset_password_instructions(tenant, email, fn token ->
      absolute_url(conn, reset_password_path(context, token))
    end)

    :ok
  end

  defp maybe_deliver_reset_password_instructions(_conn, :platform, _email), do: :ok

  defp reset_user_password({_tenant_context, tenant}, token, params) do
    TenantAccounts.reset_user_password(tenant, token, params)
  end

  defp reset_user_password(:platform, _token, _params), do: :error

  defp confirm_user({_tenant_context, tenant}, token),
    do: TenantAccounts.confirm_user(tenant, token)

  defp confirm_user(:platform, _token), do: :error

  defp change_registration(:platform) do
    Accounts.change_registration(%{}, scope: "platform", tenant_id: nil)
  end

  defp change_registration({:tenant_admin, _tenant}),
    do: TenantAccounts.change_admin_registration()

  defp change_registration({:tenant_member, _tenant}),
    do: TenantAccounts.change_member_registration()

  defp auth_title(:platform, title), do: "Platform #{title}"
  defp auth_title({:tenant_admin, tenant}, title), do: "#{tenant.name} Admin #{title}"
  defp auth_title({:tenant_member, tenant}, title), do: "#{tenant.name} #{title}"

  defp registration_title({:tenant_member, _tenant}), do: "Create account"
  defp registration_title(_context), do: "Create admin account"

  defp login_path(:platform), do: ~p"/platform/admin/login"
  defp login_path({:tenant_admin, _tenant}), do: ~p"/admin/login"
  defp login_path({:tenant_member, _tenant}), do: ~p"/login"

  defp register_path(:platform), do: ~p"/platform/admin/register"
  defp register_path({:tenant_admin, _tenant}), do: ~p"/admin/register"
  defp register_path({:tenant_member, _tenant}), do: ~p"/register"

  defp forgot_password_path(:platform), do: ~p"/platform/admin/login"
  defp forgot_password_path({:tenant_admin, _tenant}), do: ~p"/admin/forgot-password"
  defp forgot_password_path({:tenant_member, _tenant}), do: ~p"/forgot-password"

  defp reset_password_path({:tenant_admin, _tenant}, token),
    do: ~p"/admin/reset-password/#{token}"

  defp reset_password_path({:tenant_member, _tenant}, token), do: ~p"/reset-password/#{token}"
  defp reset_password_path(:platform, _token), do: ~p"/platform/admin/login"

  defp confirm_path({:tenant_admin, _tenant}, token), do: ~p"/admin/confirm/#{token}"
  defp confirm_path({:tenant_member, _tenant}, token), do: ~p"/confirm/#{token}"

  defp profile_path(:platform), do: ~p"/platform/admin/profile"
  defp profile_path({:tenant_admin, _tenant}), do: ~p"/admin/profile"
  defp profile_path({:tenant_member, _tenant}), do: ~p"/profile"

  defp password_path(:platform), do: ~p"/platform/admin/profile/password"
  defp password_path({:tenant_admin, _tenant}), do: ~p"/admin/profile/password"
  defp password_path({:tenant_member, _tenant}), do: ~p"/profile/password"

  defp admin_home_path(:platform), do: ~p"/platform/admin/plans"
  defp admin_home_path({:tenant_admin, _tenant}), do: ~p"/admin/products"
  defp admin_home_path({:tenant_member, _tenant}), do: ~p"/profile"

  defp sso_links(:platform) do
    for provider <- SSO.providers() do
      %{
        provider: provider,
        label: SSO.provider_label(provider),
        href: ~p"/platform/admin/auth/#{provider}"
      }
    end
  end

  defp sso_links({:tenant_admin, _tenant}), do: []
  defp sso_links({:tenant_member, _tenant}), do: []

  defp change_user_profile(:platform, user), do: Accounts.change_user_profile(user)

  defp change_user_profile({_tenant_context, _tenant}, user) do
    TenantAccounts.change_user_profile(user)
  end

  defp change_user_password(:platform, user), do: Accounts.change_user_password(user)

  defp change_user_password({_tenant_context, _tenant}, user) do
    TenantAccounts.change_user_password(user)
  end

  defp update_user_profile(:platform, user, params),
    do: Accounts.update_user_profile(user, params)

  defp update_user_profile({_tenant_context, tenant}, user, params) do
    TenantAccounts.update_user_profile(tenant, user, params)
  end

  defp update_user_password(:platform, user, current_password, params) do
    Accounts.update_user_password(user, current_password, params)
  end

  defp update_user_password({_tenant_context, tenant}, user, current_password, params) do
    TenantAccounts.update_user_password(tenant, user, current_password, params)
  end

  defp absolute_url(conn, path) do
    scheme = Atom.to_string(conn.scheme)
    port = if default_port?(conn.scheme, conn.port), do: "", else: ":#{conn.port}"
    "#{scheme}://#{conn.host}#{port}#{path}"
  end

  defp default_port?(:http, 80), do: true
  defp default_port?(:https, 443), do: true
  defp default_port?(_, _), do: false
end
