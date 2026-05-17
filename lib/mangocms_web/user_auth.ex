defmodule MangoCMSWeb.UserAuth do
  @moduledoc """
  Session and LiveView authentication helpers for platform and tenant admins.
  """

  use MangoCMSWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias MangoCMS.Platform.Accounts
  alias MangoCMS.Platform.Accounts.User
  alias MangoCMS.Authorization
  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.Accounts, as: TenantAccounts
  alias MangoCMS.Tenant.Accounts.User, as: TenantUser

  def fetch_current_user(conn, _opts) do
    user_token = get_session(conn, :user_token)
    user = user_from_conn(conn, user_token)
    assign(conn, :current_user, user)
  end

  def require_platform_user(conn, _opts) do
    if platform_admin_user?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "You must sign in to access platform admin.")
      |> redirect(to: ~p"/platform/admin/login")
      |> halt()
    end
  end

  def require_platform_account_user(conn, _opts) do
    if platform_account_user?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "You must sign in to access your platform account.")
      |> redirect(to: ~p"/platform/login")
      |> halt()
    end
  end

  def require_tenant_user(conn, _opts) do
    current_user = conn.assigns[:current_user]

    if tenant_admin_user?(current_user) do
      conn
    else
      conn
      |> put_flash(:error, "You must sign in to access tenant admin.")
      |> redirect(to: ~p"/admin/login")
      |> halt()
    end
  end

  def require_tenant_member_user(conn, _opts) do
    current_user = conn.assigns[:current_user]

    if tenant_user?(current_user) do
      conn
    else
      conn
      |> put_flash(:error, "You must sign in to access your account.")
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  def redirect_if_platform_user(conn, _opts) do
    if platform_admin_user?(conn.assigns[:current_user]) do
      conn
      |> redirect(to: ~p"/platform/admin/dashboard")
      |> halt()
    else
      conn
    end
  end

  def redirect_if_platform_account_user(conn, _opts) do
    current_user = conn.assigns[:current_user]

    if platform_account_user?(current_user) do
      redirect_path =
        if platform_admin_user?(current_user) do
          ~p"/platform/admin/dashboard"
        else
          ~p"/platform/dashboard"
        end

      conn
      |> redirect(to: redirect_path)
      |> halt()
    else
      conn
    end
  end

  def redirect_if_tenant_user(conn, _opts) do
    if tenant_admin_user?(conn.assigns[:current_user]) do
      conn
      |> redirect(to: ~p"/admin/collections")
      |> halt()
    else
      conn
    end
  end

  def redirect_if_tenant_member_user(conn, _opts) do
    if tenant_user?(conn.assigns[:current_user]) do
      conn
      |> redirect(to: ~p"/profile")
      |> halt()
    else
      conn
    end
  end

  def log_in_user(conn, %User{} = user) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
  end

  def log_in_user(conn, %TenantUser{} = user) do
    tenant = conn.assigns.current_tenant
    token = TenantAccounts.generate_user_session_token(tenant, user)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:tenant_id, tenant.id)
  end

  def log_out_user(conn) do
    token = get_session(conn, :user_token)
    delete_session_token(conn, token)

    conn
    |> renew_session()
    |> delete_session(:user_token)
    |> assign(:current_user, nil)
  end

  def live_session(conn) do
    %{}
    |> maybe_put_session_value("user_token", get_session(conn, :user_token))
    |> maybe_put_session_value("tenant_id", get_session(conn, :tenant_id))
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, Phoenix.Component.assign(socket, :current_user, platform_user_from_session(session))}
  end

  def on_mount(:require_platform_user, _params, session, socket) do
    user = platform_user_from_session(session)

    if platform_admin_user?(user) do
      {:cont, Phoenix.Component.assign(socket, :current_user, user)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/platform/admin/login")}
    end
  end

  def on_mount(:require_tenant_user, _params, session, socket) do
    current_tenant = socket.assigns[:current_tenant]
    user = tenant_user_from_session(current_tenant, session)

    if tenant_admin_user?(user) do
      {:cont, Phoenix.Component.assign(socket, :current_user, user)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/admin/login")}
    end
  end

  def on_mount(:mount_tenant_user, _params, session, socket) do
    current_tenant = socket.assigns[:current_tenant]
    user = tenant_user_from_session(current_tenant, session)
    {:cont, Phoenix.Component.assign(socket, :current_user, user)}
  end

  def platform_admin_user?(%User{} = user),
    do: Authorization.platform_admin_user?(user)

  def platform_admin_user?(_), do: false

  def platform_account_user?(%User{} = user),
    do: Authorization.platform_active_user?(user)

  def platform_account_user?(_), do: false

  def platform_user?(%User{} = user), do: platform_admin_user?(user)
  def platform_user?(_), do: false

  def tenant_admin_user?(%TenantUser{} = user), do: Authorization.tenant_admin_user?(user)
  def tenant_admin_user?(_), do: false

  def tenant_user?(%TenantUser{} = user), do: Authorization.tenant_active_user?(user)
  def tenant_user?(_), do: false

  defp user_from_conn(_conn, nil), do: nil

  defp user_from_conn(conn, user_token) do
    case {platform_path?(conn.request_path), conn.assigns[:current_tenant]} do
      {true, _tenant} ->
        Accounts.get_user_by_session_token(user_token)

      {false, %Tenant{} = tenant} ->
        TenantAccounts.get_user_by_session_token(tenant, user_token)

      {false, nil} ->
        Accounts.get_user_by_session_token(user_token)

      _ ->
        nil
    end
  end

  defp platform_user_from_session(%{"user_token" => user_token}) when is_binary(user_token) do
    Accounts.get_user_by_session_token(user_token)
  end

  defp platform_user_from_session(_), do: nil

  defp tenant_user_from_session(%Tenant{} = tenant, %{"user_token" => user_token})
       when is_binary(user_token) do
    TenantAccounts.get_user_by_session_token(tenant, user_token)
  end

  defp tenant_user_from_session(_, _), do: nil

  defp delete_session_token(conn, token) do
    case {conn.assigns[:current_tenant], token} do
      {%Tenant{} = tenant, token} when is_binary(token) ->
        TenantAccounts.delete_user_session_token(tenant, token)

      {_, token} when is_binary(token) ->
        Accounts.delete_user_session_token(token)

      _ ->
        :ok
    end
  end

  defp platform_path?(path), do: String.starts_with?(path, "/platform")

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_put_session_value(map, _key, nil), do: map
  defp maybe_put_session_value(map, key, value), do: Map.put(map, key, value)
end
