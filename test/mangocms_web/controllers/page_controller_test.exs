defmodule MangoCMSWeb.PageControllerTest do
  use MangoCMSWeb.ConnCase

  alias MangoCMS.Platform.Accounts
  alias MangoCMS.Platform
  alias MangoCMS.Tenant.Pages

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end

  defp plan_fixture do
    suffix = unique_suffix()

    {:ok, plan} =
      Platform.create_plan(%{
        name: "page_plan_#{suffix}",
        display_name: "Page Plan #{suffix}",
        description: "Page test plan",
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
        name: "Page Tenant #{suffix}",
        domain: "page-tenant-#{suffix}.example",
        subdomain: "page-tenant-#{suffix}",
        slug: "page_tenant_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp host_conn(conn, host), do: %{conn | host: host}

  defp with_platform_registration_enabled(fun) do
    previous = Application.get_env(:mangocms, :platform_admin_registration, [])
    Application.put_env(:mangocms, :platform_admin_registration, enabled: true)

    try do
      fun.()
    after
      Application.put_env(:mangocms, :platform_admin_registration, previous)
    end
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "Launch a polished website on #{MangoCMSWeb.Brand.name()}"
    assert html =~ "Create your company profile website"
    assert html =~ "Added AI chat feature"
    assert html =~ "id=\"plans\""
    assert html =~ "id=\"reviews\""
    assert html =~ ~p"/platform/login"
    assert html =~ ~p"/platform/register"
    refute html =~ ~p"/platform/admin/register"
  end

  test "GET / keeps platform admin registration hidden when enabled", %{conn: conn} do
    with_platform_registration_enabled(fn ->
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ ~p"/platform/register"
      refute html =~ ~p"/platform/admin/register"
    end)
  end

  test "GET / shows current platform user name and initials", %{conn: conn} do
    {conn, user} = register_and_log_in_platform_user(conn)

    {:ok, user} =
      Accounts.update_user_profile(user, %{
        email: user.email,
        full_name: "Vivek"
      })

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ user.full_name
    assert html =~ "id=\"landing-account-menu\""
    assert html =~ "id=\"landing-account-initials\""
    assert html =~ ~r/id="landing-account-initials"[^>]*>\s*V\s*<\/span>/
    assert html =~ ~p"/platform/admin/dashboard"
    assert html =~ ~p"/platform/admin/profile"
    assert html =~ ~p"/platform/admin/logout"
  end

  test "GET / shows current platform user avatar when available", %{conn: conn} do
    {conn, user} = register_and_log_in_platform_user(conn)

    {:ok, user} =
      Accounts.update_user_profile(user, %{
        email: user.email,
        full_name: "Vivek Kumar Singh",
        avatar_url: "https://example.com/vivek.png"
      })

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ user.full_name
    assert html =~ "id=\"landing-account-avatar\""
    assert html =~ "https://example.com/vivek.png"
  end

  test "GET / shows platform customer dashboard profile and logout links", %{conn: conn} do
    {conn, user} = register_and_log_in_platform_customer(conn)

    {:ok, _user} =
      Accounts.update_user_profile(user, %{
        email: user.email,
        full_name: "Platform Customer"
      })

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "id=\"landing-account-menu\""
    assert html =~ ~p"/platform/dashboard"
    assert html =~ ~p"/platform/profile"
    assert html =~ ~p"/platform/logout"
  end

  test "GET tenant / shows login and register links when logged out", %{conn: conn} do
    tenant = tenant_fixture()

    conn = conn |> host_conn(tenant.domain) |> get(~p"/")
    html = html_response(conn, 200)

    assert html =~ ~p"/login"
    assert html =~ ~p"/register"
  end

  test "GET tenant / shows tenant admin dropdown links when logged in", %{conn: conn} do
    tenant = tenant_fixture()
    {conn, user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ user.full_name
    assert html =~ "id=\"landing-account-menu\""
    assert html =~ ~p"/admin/dashboard"
    assert html =~ ~p"/admin/profile"
    assert html =~ ~p"/admin/logout"
  end

  test "GET tenant published page shows floating edit button for page managers", %{conn: conn} do
    tenant = tenant_fixture()

    {:ok, page} =
      Pages.create_page(tenant, %{
        title: "About",
        slug: "about",
        type: "page",
        status: "published",
        seo: %{}
      })

    {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

    conn = get(conn, ~p"/about")
    html = html_response(conn, 200)

    assert html =~ "id=\"public-page-edit-button\""
    assert html =~ ~p"/admin/pages/#{page}/builder"
  end
end
