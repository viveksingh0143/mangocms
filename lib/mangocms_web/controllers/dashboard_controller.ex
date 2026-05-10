defmodule MangoCMSWeb.DashboardController do
  use MangoCMSWeb, :controller

  def platform_admin(conn, _params) do
    render(conn, :platform_admin, title: "Platform Dashboard")
  end

  def platform(conn, _params) do
    render(conn, :platform, title: "Dashboard")
  end

  def tenant_admin(conn, _params) do
    render(conn, :tenant_admin, title: "Tenant Dashboard")
  end

  def tenant_member(conn, _params) do
    render(conn, :tenant_member, title: "Dashboard")
  end
end
