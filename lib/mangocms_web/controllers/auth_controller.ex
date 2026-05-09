defmodule MangoCMSWeb.AuthController do
  use MangoCMSWeb, :controller
  import Phoenix.Component, only: [to_form: 1, to_form: 2]

  alias MangoCMS.Accounts
  alias MangoCMS.Accounts.SSO
  alias MangoCMSWeb.UserAuth

  def new(conn, _params) do
    context = auth_context(conn)

    render(conn, :login,
      form: to_form(%{}, as: :user),
      title: auth_title(context, "Sign in"),
      context: context,
      action: login_path(context),
      register_path: register_path(context),
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
          sso_links: sso_links(context)
        )
    end
  end

  def register(conn, _params) do
    context = auth_context(conn)

    render(conn, :register,
      form: to_form(Accounts.change_registration(%{}, registration_opts(context))),
      title: auth_title(context, "Create admin account"),
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
        conn
        |> put_flash(:info, "Account created successfully.")
        |> UserAuth.log_in_user(user)
        |> redirect(to: admin_home_path(context))

      {:error, changeset} ->
        render(conn, :register,
          form: to_form(changeset),
          title: auth_title(context, "Create admin account"),
          context: context,
          action: register_path(context),
          login_path: login_path(context),
          sso_links: sso_links(context)
        )
    end
  end

  def edit_profile(conn, _params) do
    context = auth_context(conn)
    user = conn.assigns.current_user

    render(conn, :profile,
      title: auth_title(context, "Profile"),
      context: context,
      user: user,
      profile_form: to_form(Accounts.change_user_profile(user), as: :user),
      password_form: to_form(Accounts.change_user_password(user), as: :user),
      profile_action: profile_path(context),
      password_action: password_path(context),
      back_path: admin_home_path(context)
    )
  end

  def update_profile(conn, %{"user" => user_params}) do
    context = auth_context(conn)
    user = conn.assigns.current_user

    case Accounts.update_user_profile(user, user_params) do
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
          password_form: to_form(Accounts.change_user_password(user), as: :user),
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

    case Accounts.update_user_password(user, current_password, user_params) do
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
          profile_form: to_form(Accounts.change_user_profile(user), as: :user),
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
    if String.starts_with?(conn.request_path, "/platform/admin") do
      :platform
    else
      {:tenant, conn.assigns.current_tenant}
    end
  end

  defp authenticate(:platform, email, password),
    do: Accounts.authenticate_platform_user(email, password)

  defp authenticate({:tenant, tenant}, email, password) do
    Accounts.authenticate_tenant_user(tenant, email, password)
  end

  defp register_user(:platform, params), do: Accounts.register_platform_user(params)

  defp register_user({:tenant, tenant}, params) do
    Accounts.register_tenant_user(tenant, params)
  end

  defp registration_opts(:platform), do: [scope: "platform", tenant_id: nil]

  defp registration_opts({:tenant, tenant}) do
    [scope: "tenant", tenant_id: tenant.id]
  end

  defp auth_title(:platform, title), do: "Platform #{title}"
  defp auth_title({:tenant, tenant}, title), do: "#{tenant.name} #{title}"

  defp login_path(:platform), do: ~p"/platform/admin/login"
  defp login_path({:tenant, _tenant}), do: ~p"/admin/login"

  defp register_path(:platform), do: ~p"/platform/admin/register"
  defp register_path({:tenant, _tenant}), do: ~p"/admin/register"

  defp profile_path(:platform), do: ~p"/platform/admin/profile"
  defp profile_path({:tenant, _tenant}), do: ~p"/admin/profile"

  defp password_path(:platform), do: ~p"/platform/admin/profile/password"
  defp password_path({:tenant, _tenant}), do: ~p"/admin/profile/password"

  defp admin_home_path(:platform), do: ~p"/platform/admin/plans"
  defp admin_home_path({:tenant, _tenant}), do: ~p"/admin/products"

  defp sso_links(:platform) do
    for provider <- SSO.providers() do
      %{
        provider: provider,
        label: SSO.provider_label(provider),
        href: ~p"/platform/admin/auth/#{provider}"
      }
    end
  end

  defp sso_links({:tenant, _tenant}) do
    for provider <- SSO.providers() do
      %{
        provider: provider,
        label: SSO.provider_label(provider),
        href: ~p"/admin/auth/#{provider}"
      }
    end
  end
end
