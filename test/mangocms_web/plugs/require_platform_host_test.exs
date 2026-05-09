defmodule MangoCMSWeb.Plugs.RequirePlatformHostTest do
  use MangoCMSWeb.ConnCase

  alias MangoCMS.Platform

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end

  defp plan_fixture do
    suffix = unique_suffix()

    {:ok, plan} =
      Platform.create_plan(%{
        name: "platform_guard_#{suffix}",
        display_name: "Platform Guard #{suffix}",
        description: "Guard test plan",
        price_monthly: 99900,
        price_yearly: 9_99000,
        currency: "INR",
        max_pages: 100,
        max_storage_mb: 5000,
        max_api_calls_per_day: 10_000,
        max_users: 5,
        max_domains: 3,
        max_media_files: 1000
      })

    plan
  end

  defp tenant_fixture do
    suffix = unique_suffix()
    plan = plan_fixture()

    {:ok, tenant} =
      Platform.create_tenant(%{
        name: "Tenant Guard #{suffix}",
        domain: "tenant-guard-#{suffix}.example",
        subdomain: "tenant-guard-#{suffix}",
        slug: "tenant_guard_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp host_conn(conn, host), do: %{conn | host: host}

  test "allows platform routes on a non-tenant host", %{conn: conn} do
    {conn, _user} = register_and_log_in_platform_user(conn)
    conn = get(host_conn(conn, "localhost"), ~p"/platform/admin/plans")

    assert html_response(conn, 200) =~ "Platform plans"
  end

  test "blocks platform routes on a tenant custom domain", %{conn: conn} do
    tenant = tenant_fixture()
    conn = get(host_conn(conn, tenant.domain), ~p"/platform/admin/plans")

    assert response(conn, 404) == "Not found"
  end

  test "blocks platform routes on a tenant platform subdomain", %{conn: conn} do
    tenant = tenant_fixture()
    conn = get(host_conn(conn, "#{tenant.subdomain}.mangocms.local"), ~p"/platform/admin/tenants")

    assert response(conn, 404) == "Not found"
  end
end
