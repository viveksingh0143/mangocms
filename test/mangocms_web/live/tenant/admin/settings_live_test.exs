defmodule MangoCMSWeb.Tenant.Admin.SettingsLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform
  alias MangoCMS.TenantAccounts
  alias MangoCMS.TenantSettings

  defp unique_suffix, do: System.unique_integer([:positive]) |> Integer.to_string()

  defp plan_fixture do
    suffix = unique_suffix()

    {:ok, plan} =
      Platform.create_plan(%{
        name: "settings_plan_#{suffix}",
        display_name: "Settings Plan #{suffix}",
        description: "Tenant settings plan",
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
        name: "Settings Tenant #{suffix}",
        domain: "settings-tenant-#{suffix}.example",
        subdomain: "settings-tenant-#{suffix}",
        slug: "settings_tenant_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })
      |> Platform.create_tenant()

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp host_conn(conn, host), do: %{conn | host: host}

  describe "Edit" do
    test "updates tenant-local site settings and reflects them in tenant UI", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, settings_live, html} = live(conn, ~p"/admin/settings")

      assert html =~ "Tenant settings"
      assert html =~ "id=\"tenant-settings-form\""

      attrs = %{
        site_name: "Acme Knowledge Base",
        tagline: "Answers for every visitor",
        logo_url: "https://example.com/acme-light.png",
        dark_logo_url: "https://example.com/acme-dark.png",
        support_email: "support@acme.example",
        locale: "en",
        timezone: "Asia/Kolkata"
      }

      assert settings_live
             |> form("#tenant-settings-form", site_settings: attrs)
             |> render_submit() =~ "Tenant settings updated successfully."

      settings = TenantSettings.get_site_settings(tenant)
      assert settings.site_name == "Acme Knowledge Base"
      assert settings.logo_url == "https://example.com/acme-light.png"

      html = conn |> get(~p"/") |> html_response(200)

      assert html =~ "Acme Knowledge Base"
      assert html =~ "https://example.com/acme-light.png"
      assert html =~ "https://example.com/acme-dark.png"
    end

    test "tenant staff cannot manage settings", %{conn: conn} do
      tenant = tenant_fixture()

      {:ok, staff} =
        TenantAccounts.create_user(tenant, %{
          full_name: "Staff User",
          email: "staff-#{unique_suffix()}@example.com",
          password: "valid-password-123",
          role: "staff",
          locale: "en",
          timezone: "UTC"
        })

      conn =
        conn
        |> host_conn(tenant.domain)
        |> log_in_tenant_user(tenant, staff)

      assert {:error, {:redirect, %{to: "/admin/dashboard"}}} =
               live(conn, ~p"/admin/settings")
    end
  end
end
