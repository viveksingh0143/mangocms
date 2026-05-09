defmodule MangoCMSWeb.UserAuth do
  @moduledoc """
  Session and LiveView authentication helpers for platform and tenant admins.
  """

  use MangoCMSWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias MangoCMS.Accounts
  alias MangoCMS.Accounts.User
  alias MangoCMS.Platform.Tenant

  def fetch_current_user(conn, _opts) do
    user_token = get_session(conn, :user_token)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  def require_platform_user(conn, _opts) do
    if platform_user?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "You must sign in to access platform admin.")
      |> redirect(to: ~p"/platform/admin/login")
      |> halt()
    end
  end

  def require_tenant_user(conn, _opts) do
    current_tenant = conn.assigns[:current_tenant]
    current_user = conn.assigns[:current_user]

    if tenant_user?(current_user, current_tenant) do
      conn
    else
      conn
      |> put_flash(:error, "You must sign in to access tenant admin.")
      |> redirect(to: ~p"/admin/login")
      |> halt()
    end
  end

  def redirect_if_platform_user(conn, _opts) do
    if platform_user?(conn.assigns[:current_user]) do
      conn
      |> redirect(to: ~p"/platform/admin/plans")
      |> halt()
    else
      conn
    end
  end

  def redirect_if_tenant_user(conn, _opts) do
    if tenant_user?(conn.assigns[:current_user], conn.assigns[:current_tenant]) do
      conn
      |> redirect(to: ~p"/admin/products")
      |> halt()
    else
      conn
    end
  end

  def log_in_user(conn, %User{} = user) do
    token = Accounts.generate_user_session_token(user)
    tenant_id = conn.assigns[:current_tenant] && conn.assigns.current_tenant.id

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> maybe_put_tenant_session(tenant_id)
  end

  def log_out_user(conn) do
    token = get_session(conn, :user_token)
    token && Accounts.delete_user_session_token(token)

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
    {:cont, Phoenix.Component.assign(socket, :current_user, user_from_session(session))}
  end

  def on_mount(:require_platform_user, _params, session, socket) do
    user = user_from_session(session)

    if platform_user?(user) do
      {:cont, Phoenix.Component.assign(socket, :current_user, user)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/platform/admin/login")}
    end
  end

  def on_mount(:require_tenant_user, _params, session, socket) do
    user = user_from_session(session)
    current_tenant = socket.assigns[:current_tenant]

    if tenant_user?(user, current_tenant) do
      {:cont, Phoenix.Component.assign(socket, :current_user, user)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/admin/login")}
    end
  end

  def platform_user?(%User{} = user), do: User.platform?(user) and not User.disabled?(user)
  def platform_user?(_), do: false

  def tenant_user?(%User{} = user, %Tenant{id: tenant_id}) do
    User.tenant?(user, tenant_id) and not User.disabled?(user)
  end

  def tenant_user?(_, _), do: false

  defp user_from_session(%{"user_token" => user_token}) when is_binary(user_token) do
    Accounts.get_user_by_session_token(user_token)
  end

  defp user_from_session(_), do: nil

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_put_tenant_session(conn, nil), do: conn
  defp maybe_put_tenant_session(conn, tenant_id), do: put_session(conn, :tenant_id, tenant_id)

  defp maybe_put_session_value(map, _key, nil), do: map
  defp maybe_put_session_value(map, key, value), do: Map.put(map, key, value)
end
