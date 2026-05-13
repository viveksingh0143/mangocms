defmodule MangoCMSWeb.Tenant.Admin.UserLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform
  alias MangoCMS.TenantAccounts

  @create_attrs %{
    full_name: "Managed Tenant User",
    email: "managed-tenant-user@example.com",
    password: "valid-password-123",
    role: "staff",
    phone: "+15550000003",
    avatar_url: "https://example.com/tenant-user.png",
    locale: "en",
    timezone: "UTC"
  }

  @update_attrs %{
    full_name: "Updated Tenant User",
    email: "updated-tenant-user@example.com",
    password: "",
    role: "member",
    phone: "+15550000004",
    avatar_url: "https://example.com/tenant-user-updated.png",
    locale: "en",
    timezone: "Asia/Kolkata"
  }

  @invalid_attrs %{
    full_name: "",
    email: "",
    password: "short",
    role: "staff"
  }

  defp unique_suffix, do: System.unique_integer([:positive]) |> Integer.to_string()

  defp unique_email(prefix) do
    "#{prefix}-#{unique_suffix()}@example.com"
  end

  defp plan_fixture do
    suffix = unique_suffix()

    {:ok, plan} =
      Platform.create_plan(%{
        name: "tenant_user_plan_#{suffix}",
        display_name: "Tenant User Plan #{suffix}",
        description: "Tenant user plan",
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

  defp tenant_fixture(attrs \\ %{}) do
    suffix = unique_suffix()
    plan = plan_fixture()

    {:ok, tenant} =
      attrs
      |> Enum.into(%{
        name: "Tenant User #{suffix}",
        domain: "tenant-user-#{suffix}.example",
        subdomain: "tenant-user-#{suffix}",
        slug: "tenant_user_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })
      |> Platform.create_tenant()

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp managed_tenant_user_fixture(tenant, attrs \\ %{}) do
    attrs =
      @create_attrs
      |> Map.put(:email, unique_email("managed-tenant"))
      |> Map.merge(attrs)

    {:ok, user} = TenantAccounts.create_user(tenant, attrs)
    user
  end

  defp host_conn(conn, host), do: %{conn | host: host}

  describe "Index" do
    test "lists tenant-local users", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _index_live, html} = live(conn, ~p"/admin/users")

      assert html =~ "Tenant users"
      assert html =~ user.email
      assert html =~ "id=\"new-tenant-user-button\""
    end

    test "creates tenant-local user", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("#new-tenant-user-button") |> render_click() =~
               "New tenant user"

      assert index_live
             |> form("#tenant-user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      attrs = Map.put(@create_attrs, :email, unique_email("new-tenant"))

      assert index_live
             |> form("#tenant-user-form", user: attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/users")
      assert render(index_live) =~ attrs.full_name
      assert TenantAccounts.get_user_by_email(tenant, attrs.email).role == "staff"
    end

    test "updates tenant-local user", %{conn: conn} do
      tenant = tenant_fixture()
      user = managed_tenant_user_fixture(tenant)
      {conn, _admin} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("#edit-tenant-user-#{user.id}") |> render_click() =~
               "Edit tenant user"

      attrs = Map.put(@update_attrs, :email, unique_email("updated-tenant"))

      assert index_live
             |> form("#tenant-user-form", user: attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/users")
      html = render(index_live)
      assert html =~ "Updated Tenant User"
      refute html =~ user.email
    end

    test "deletes tenant-local user but not the current user", %{conn: conn} do
      tenant = tenant_fixture()
      user = managed_tenant_user_fixture(tenant)
      {conn, admin} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("#delete-tenant-user-#{user.id}") |> render_click()
      refute has_element?(index_live, "#users-#{user.id}")

      assert index_live
             |> element("#delete-tenant-user-#{admin.id}")
             |> render_click() =~ "You cannot delete your own account."

      assert has_element?(index_live, "#users-#{admin.id}")
    end

    test "tenant staff can use admin area but cannot manage users", %{conn: conn} do
      tenant = tenant_fixture()
      staff = managed_tenant_user_fixture(tenant, %{role: "staff", email: unique_email("staff")})

      conn =
        conn
        |> host_conn(tenant.domain)
        |> log_in_tenant_user(tenant, staff)

      assert {:error, {:redirect, %{to: "/admin/dashboard"}}} = live(conn, ~p"/admin/users")
    end
  end
end
