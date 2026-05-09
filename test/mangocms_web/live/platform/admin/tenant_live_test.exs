defmodule MangoCMSWeb.Platform.Admin.TenantLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform

  @plan_attrs %{
    name: "growth",
    display_name: "Growth",
    description: "For growing teams",
    price_monthly: 99900,
    price_yearly: 9_99000,
    currency: "INR",
    max_pages: 100,
    max_storage_mb: 5000,
    max_api_calls_per_day: 10_000,
    max_users: 5,
    max_domains: 3,
    max_media_files: 1000
  }

  @tenant_attrs %{
    name: "Acme Publishing",
    domain: "acme.example",
    subdomain: "acme",
    slug: "acme",
    status: "trialing",
    active: true
  }

  @update_attrs %{
    name: "Orbit Media",
    domain: "orbit.example",
    subdomain: "orbit",
    slug: "orbit",
    status: "active",
    billing_cycle: "monthly",
    active: true,
    external_customer_id: "cus_orbit",
    external_subscription_id: "sub_orbit"
  }

  @invalid_attrs %{
    name: nil,
    domain: "invalid",
    subdomain: "Nope",
    slug: "Bad Slug",
    plan_id: nil
  }

  defp plan_fixture(attrs \\ %{}) do
    {:ok, plan} =
      attrs
      |> Enum.into(@plan_attrs)
      |> Platform.create_plan()

    plan
  end

  defp tenant_fixture(attrs \\ %{}) do
    plan = plan_fixture()

    {:ok, tenant} =
      attrs
      |> Enum.into(@tenant_attrs)
      |> Map.put(:plan_id, plan.id)
      |> Platform.create_tenant()

    Platform.get_tenant_with_plan!(tenant.id)
  end

  setup %{conn: conn} do
    {conn, user} = register_and_log_in_platform_user(conn)
    %{conn: conn, platform_user: user}
  end

  describe "Index" do
    test "lists all tenants with their plans", %{conn: conn} do
      tenant = tenant_fixture()
      {:ok, _index_live, html} = live(conn, ~p"/platform/admin/tenants")

      assert html =~ "Platform tenants"
      assert html =~ tenant.name
      assert html =~ tenant.plan.display_name
    end

    test "saves new tenant with a plan association", %{conn: conn} do
      plan = plan_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/tenants")

      assert index_live |> element("#new-tenant-button") |> render_click() =~ "New tenant"

      assert index_live
             |> form("#tenant-form", tenant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tenant-form", tenant: Map.put(@tenant_attrs, :plan_id, plan.id))
             |> render_submit()

      assert_patch(index_live, ~p"/platform/admin/tenants")
      html = render(index_live)
      assert html =~ "Acme Publishing"
      assert html =~ "Growth"
    end

    test "updates tenant and switches its plan", %{conn: conn} do
      tenant = tenant_fixture()
      scale_plan = plan_fixture(%{name: "scale", display_name: "Scale", sort_order: 2})
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/tenants")

      assert index_live |> element("#edit-tenant-#{tenant.id}") |> render_click() =~ "Edit tenant"

      assert index_live
             |> form("#tenant-form", tenant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tenant-form", tenant: Map.put(@update_attrs, :plan_id, scale_plan.id))
             |> render_submit()

      assert_patch(index_live, ~p"/platform/admin/tenants")
      html = render(index_live)
      assert html =~ "Orbit Media"
      assert html =~ "Scale"
      refute html =~ "Acme Publishing"
    end

    test "deletes tenant in listing", %{conn: conn} do
      tenant = tenant_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/tenants")

      assert index_live |> element("#delete-tenant-#{tenant.id}") |> render_click()
      refute has_element?(index_live, "#tenants-#{tenant.id}")
    end
  end

  describe "Show" do
    test "displays tenant and associated plan", %{conn: conn} do
      tenant = tenant_fixture()
      {:ok, _show_live, html} = live(conn, ~p"/platform/admin/tenants/#{tenant}")

      assert html =~ tenant.name
      assert html =~ tenant.plan.display_name
      assert html =~ "Storage"
    end

    test "updates tenant within show", %{conn: conn} do
      tenant = tenant_fixture()
      scale_plan = plan_fixture(%{name: "show_scale", display_name: "Show Scale", sort_order: 2})
      {:ok, show_live, _html} = live(conn, ~p"/platform/admin/tenants/#{tenant}")

      assert show_live |> element("#edit-tenant-button") |> render_click() =~ "Edit tenant"

      assert show_live
             |> form("#tenant-form", tenant: Map.put(@update_attrs, :plan_id, scale_plan.id))
             |> render_submit()

      assert_patch(show_live, ~p"/platform/admin/tenants/#{tenant}")
      html = render(show_live)
      assert html =~ "Orbit Media"
      assert html =~ "Show Scale"
    end
  end
end
