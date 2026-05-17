defmodule MangoCMSWeb.AuthControllerTest do
  use MangoCMSWeb.ConnCase

  alias MangoCMS.Platform.Accounts
  alias MangoCMS.Platform
  alias MangoCMS.Tenant.Accounts, as: TenantAccounts

  @password "valid-password-123"

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end

  defp plan_fixture do
    suffix = unique_suffix()

    {:ok, plan} =
      Platform.create_plan(%{
        name: "auth_plan_#{suffix}",
        display_name: "Auth Plan #{suffix}",
        description: "Auth test plan",
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
        name: "Auth Tenant #{suffix}",
        domain: "auth-tenant-#{suffix}.example",
        subdomain: "auth-tenant-#{suffix}",
        slug: "auth_tenant_#{suffix}",
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

  describe "platform auth" do
    test "shows login and register links on platform login and register headers", %{conn: conn} do
      login_conn = get(conn, ~p"/platform/login")
      login_html = html_response(login_conn, 200)

      assert login_html =~ "id=\"admin-login-link\""
      assert login_html =~ "id=\"admin-register-link\""
      assert login_html =~ ~p"/platform/login"
      assert login_html =~ ~p"/platform/register"
      assert login_html =~ "href=\"/\""

      register_conn = get(conn, ~p"/platform/register")
      register_html = html_response(register_conn, 200)

      assert register_html =~ "id=\"admin-login-link\""
      assert register_html =~ "id=\"admin-register-link\""
      assert register_html =~ ~p"/platform/login"
      assert register_html =~ ~p"/platform/register"
      assert register_html =~ "href=\"/\""
    end

    test "blocks platform admin registration by default", %{conn: conn} do
      conn =
        post(conn, ~p"/platform/admin/register",
          user: %{
            email: "blocked-platform@example.com",
            password: @password,
            full_name: "Blocked Platform"
          }
        )

      assert text_response(conn, 404) == "Not found"
    end

    test "registers a platform admin when explicitly enabled", %{conn: conn} do
      suffix = unique_suffix()

      with_platform_registration_enabled(fn ->
        conn =
          post(conn, ~p"/platform/admin/register",
            user: %{
              email: "platform-register-#{suffix}@example.com",
              password: @password,
              full_name: "Platform Register",
              timezone: "UTC",
              locale: "en"
            }
          )

        assert redirected_to(conn) == ~p"/platform/admin/dashboard"
        assert get_session(conn, :user_token)
      end)
    end

    test "registers a platform customer account", %{conn: conn} do
      suffix = unique_suffix()

      conn =
        post(conn, ~p"/platform/register",
          user: %{
            email: "platform-customer-#{suffix}@example.com",
            password: @password,
            full_name: "Platform Customer",
            timezone: "UTC",
            locale: "en"
          }
        )

      assert redirected_to(conn) == ~p"/platform/dashboard"
      assert get_session(conn, :user_token)

      assert {:ok, user} =
               Accounts.authenticate_platform_user(
                 "platform-customer-#{suffix}@example.com",
                 @password
               )

      assert user.role == "customer"
    end

    test "logs in a platform admin", %{conn: conn} do
      user = platform_user_fixture()

      conn =
        post(conn, ~p"/platform/admin/login", user: %{email: user.email, password: @password})

      assert redirected_to(conn) == ~p"/platform/admin/dashboard"
      assert get_session(conn, :user_token)
    end

    test "shows platform admin dashboard with CRUD options and current user", %{conn: conn} do
      {conn, user} = register_and_log_in_platform_user(conn)

      {:ok, user} =
        Accounts.update_user_profile(user, %{
          email: user.email,
          full_name: "Vivek Kumar Singh"
        })

      conn = get(conn, ~p"/platform/admin/dashboard")
      html = html_response(conn, 200)

      assert html =~ "id=\"platform-admin-dashboard\""
      assert html =~ "id=\"dashboard-plans-link\""
      assert html =~ "id=\"dashboard-tenants-link\""
      assert html =~ user.email
      assert html =~ "Vivek Kumar Singh"
      assert html =~ "VK"
    end

    test "does not allow platform customers into platform admin", %{conn: conn} do
      {conn, _user} = register_and_log_in_platform_customer(conn)

      conn = get(conn, ~p"/platform/admin/plans")

      assert redirected_to(conn) == ~p"/platform/admin/login"
    end

    test "shows platform customer dashboard with profile actions", %{conn: conn} do
      {conn, _user} = register_and_log_in_platform_customer(conn)

      conn = get(conn, ~p"/platform/dashboard")
      html = html_response(conn, 200)

      assert html =~ "id=\"platform-dashboard\""
      assert html =~ "id=\"dashboard-profile-link\""
      refute html =~ "id=\"dashboard-plans-link\""
    end

    test "updates platform profile and password", %{conn: conn} do
      {conn, user} = register_and_log_in_platform_user(conn)

      conn =
        put(conn, ~p"/platform/admin/profile",
          user: %{email: user.email, full_name: "Updated Platform", timezone: "Asia/Kolkata"}
        )

      assert redirected_to(conn) == ~p"/platform/admin/profile"
      assert Accounts.get_user!(user.id).full_name == "Updated Platform"

      conn =
        put(conn, ~p"/platform/admin/profile/password",
          user: %{current_password: @password, password: "new-password-123"}
        )

      assert redirected_to(conn) == ~p"/platform/admin/profile"
      assert {:ok, _user} = Accounts.authenticate_platform_user(user.email, "new-password-123")
    end

    test "redirects unauthenticated platform admin to login", %{conn: conn} do
      conn = get(conn, ~p"/platform/admin/plans")

      assert redirected_to(conn) == ~p"/platform/admin/login"
    end
  end

  describe "tenant auth" do
    test "shows login and register links on tenant member login and register headers", %{
      conn: conn
    } do
      tenant = tenant_fixture()

      login_conn = conn |> host_conn(tenant.domain) |> get(~p"/login")
      login_html = html_response(login_conn, 200)

      assert login_html =~ "id=\"admin-login-link\""
      assert login_html =~ "id=\"admin-register-link\""
      assert login_html =~ ~p"/login"
      assert login_html =~ ~p"/register"
      assert login_html =~ "href=\"/\""

      register_conn = conn |> host_conn(tenant.domain) |> get(~p"/register")
      register_html = html_response(register_conn, 200)

      assert register_html =~ "id=\"admin-login-link\""
      assert register_html =~ "id=\"admin-register-link\""
      assert register_html =~ ~p"/login"
      assert register_html =~ ~p"/register"
      assert register_html =~ "href=\"/\""
    end

    test "does not expose tenant admin registration", %{conn: conn} do
      tenant = tenant_fixture()

      conn =
        conn
        |> host_conn(tenant.domain)
        |> post("/admin/register",
          user: %{
            email: "tenant-register@example.com",
            password: @password,
            full_name: "Tenant Register"
          }
        )

      assert response(conn, 404)
    end

    test "updates tenant profile", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      conn =
        put(conn, ~p"/admin/profile",
          user: %{email: user.email, full_name: "Updated Tenant", timezone: "Asia/Kolkata"}
        )

      assert redirected_to(conn) == ~p"/admin/profile"
      assert TenantAccounts.get_user!(tenant, user.id).full_name == "Updated Tenant"
    end

    test "shows tenant admin dashboard with collections option and current user", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, user} =
        TenantAccounts.update_user_profile(tenant, user, %{
          email: user.email,
          avatar_url: "https://example.com/tenant-avatar.png"
        })

      conn = get(conn, ~p"/admin/dashboard")
      html = html_response(conn, 200)

      assert html =~ "id=\"tenant-admin-dashboard\""
      assert html =~ "id=\"dashboard-collections-link\""
      assert html =~ user.email
      assert html =~ "https://example.com/tenant-avatar.png"
    end

    test "registers and logs into a tenant member", %{conn: conn} do
      tenant = tenant_fixture()
      suffix = unique_suffix()

      conn =
        conn
        |> host_conn(tenant.domain)
        |> post(~p"/register",
          user: %{
            email: "tenant-member-#{suffix}@example.com",
            password: @password,
            full_name: "Tenant Member",
            timezone: "UTC",
            locale: "en"
          }
        )

      assert redirected_to(conn) == ~p"/dashboard"
      assert get_session(conn, :user_token)
      assert get_session(conn, :tenant_id) == tenant.id
    end

    test "resets tenant member password", %{conn: conn} do
      tenant = tenant_fixture()
      suffix = unique_suffix()

      {:ok, user} =
        TenantAccounts.register_member_user(tenant, %{
          email: "reset-member-#{suffix}@example.com",
          password: @password,
          full_name: "Reset Member"
        })

      token = TenantAccounts.generate_reset_password_token(tenant, user)

      conn =
        conn
        |> host_conn(tenant.domain)
        |> put(~p"/reset-password/#{token}", user: %{password: "changed-password-123"})

      assert redirected_to(conn) == ~p"/login"

      assert {:ok, _user} =
               TenantAccounts.authenticate_user(tenant, user.email, "changed-password-123")
    end

    test "confirms tenant member email", %{conn: conn} do
      tenant = tenant_fixture()
      suffix = unique_suffix()

      {:ok, user} =
        TenantAccounts.register_member_user(tenant, %{
          email: "confirm-member-#{suffix}@example.com",
          password: @password,
          full_name: "Confirm Member"
        })

      token = TenantAccounts.generate_confirmation_token(tenant, user)

      conn =
        conn
        |> host_conn(tenant.domain)
        |> get(~p"/confirm/#{token}")

      assert redirected_to(conn) == ~p"/login"
      assert TenantAccounts.get_user!(tenant, user.id).confirmed_at
    end
  end

  test "SSO request redirects back when provider is not configured", %{conn: conn} do
    conn = get(conn, ~p"/platform/admin/auth/google")

    assert redirected_to(conn) == ~p"/platform/admin/login"
  end
end
