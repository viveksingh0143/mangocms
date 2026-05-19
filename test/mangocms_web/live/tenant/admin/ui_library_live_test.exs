defmodule MangoCMSWeb.Tenant.Admin.UILibraryLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform

  # ── Fixtures ──────────────────────────────────────────────────────────────────

  defp unique_suffix, do: System.unique_integer([:positive]) |> Integer.to_string()

  defp plan_fixture do
    suffix = unique_suffix()

    {:ok, plan} =
      Platform.create_plan(%{
        name: "ui_library_plan_#{suffix}",
        display_name: "UI Library Plan #{suffix}",
        description: "For UI Library tests",
        price_monthly: 9900,
        price_yearly: 99_000,
        currency: "USD",
        max_pages: 50,
        max_storage_mb: 1000,
        max_api_calls_per_day: 5000,
        max_users: 3,
        max_domains: 2,
        max_media_files: 500
      })

    plan
  end

  defp tenant_fixture do
    suffix = unique_suffix()
    plan = plan_fixture()

    {:ok, tenant} =
      Platform.create_tenant(%{
        name: "UI Library Tenant #{suffix}",
        domain: "ui-library-#{suffix}.example",
        subdomain: "ui-library-#{suffix}",
        slug: "ui_library_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp host_conn(conn, host, port \\ 80), do: %{conn | host: host, port: port}

  # ── Route access ──────────────────────────────────────────────────────────────

  describe "route access" do
    test "redirects unauthenticated visitor to login", %{conn: conn} do
      tenant = tenant_fixture()
      conn = host_conn(conn, tenant.domain)

      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/admin/ui-library")
      assert path =~ "/login"
    end

    test "authenticated user reaches the index page", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _lv, html} = live(conn, ~p"/admin/ui-library")

      assert html =~ "UI Library"
    end

    test "authenticated user reaches a component detail page", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _lv, html} = live(conn, ~p"/admin/ui-library/button")

      assert html =~ "Button"
    end

    test "unknown component name redirects back to index", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      assert {:error, {:live_redirect, %{to: path}}} =
               live(conn, ~p"/admin/ui-library/definitely_not_a_component")

      assert path == ~p"/admin/ui-library"
    end
  end

  # ── Registry rendering ────────────────────────────────────────────────────────

  describe "component registry rendering" do
    test "index lists components from all groups", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _lv, html} = live(conn, ~p"/admin/ui-library")

      # Group filter buttons
      assert html =~ "All"
      assert html =~ "Action"
      assert html =~ "Data display"
      assert html =~ "Data input"
      assert html =~ "Feedback"
      assert html =~ "Layout"
      assert html =~ "Navigation"
      assert html =~ "Mockup"

      # Representative components from each group
      assert html =~ "Button"
      assert html =~ "Alert"
      assert html =~ "Input"
      assert html =~ "Card"
      assert html =~ "Navbar"
      assert html =~ "Browser mockup"
    end

    test "index shows per-group component count badge", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _lv, html} = live(conn, ~p"/admin/ui-library")

      # The "All" group button should have the total count
      total = MangoCMSWeb.Builder.Registry.all() |> length()
      assert html =~ Integer.to_string(total)
    end

    test "component detail shows variant tabs and inspector", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _lv, html} = live(conn, ~p"/admin/ui-library/button")

      # Variant tabs (button has primary / ghost)
      assert html =~ "Primary"
      assert html =~ "Ghost"

      # Inspector header
      assert html =~ "Action"

      # Inspector fields (button has a text field with label "Text")
      assert html =~ "Text"
    end

    test "detail page shows meta badges for slots and Alpine", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      # Hero has slots and Alpine
      {:ok, _lv, html} = live(conn, ~p"/admin/ui-library/hero")

      assert html =~ "Slot:"
      assert html =~ "Alpine.js"
    end

    test "detail page shows responsive controls", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _lv, html} = live(conn, ~p"/admin/ui-library/button")

      assert html =~ "Desktop"
      assert html =~ "Tablet"
      assert html =~ "Mobile"
    end
  end

  # ── Filters ───────────────────────────────────────────────────────────────────

  describe "filters" do
    test "search filters components by name", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library")

      html = lv |> form("form[phx-change=search]", %{q: "button"}) |> render_change()

      assert html =~ "Button"
      refute html =~ "Alert"
      refute html =~ "Accordion"
    end

    test "search filters components by group name", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library")

      html = lv |> form("form[phx-change=search]", %{q: "mockup"}) |> render_change()

      assert html =~ "Browser mockup"
      assert html =~ "Code mockup"
      refute html =~ "Button"
    end

    test "empty search shows empty state", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library")

      html = lv |> form("form[phx-change=search]", %{q: "zzznomatch"}) |> render_change()

      assert html =~ "No components match"
      refute html =~ "Button"
    end

    test "group filter shows only components in that group", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library")

      html = lv |> element("button[phx-value-group=Feedback]") |> render_click()

      assert html =~ "Alert"
      assert html =~ "Loading"
      refute html =~ "Button"
      refute html =~ "Accordion"
    end

    test "All group filter restores full list", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library")

      lv |> element("button[phx-value-group=Feedback]") |> render_click()
      html = lv |> element("button[phx-value-group=All]") |> render_click()

      assert html =~ "Button"
      assert html =~ "Alert"
      assert html =~ "Accordion"
    end
  end

  # ── Property updates via inspector ────────────────────────────────────────────

  describe "property updates" do
    test "changing a text prop updates the preview", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, initial_html} = live(conn, ~p"/admin/ui-library/button")

      # Default label is "Button" for the button component
      assert initial_html =~ "Button"

      # Change label via inspector form
      html =
        lv
        |> form("form[phx-change=update_props]",
          node: %{props: %{label: "Book now"}}
        )
        |> render_change()

      assert html =~ "Book now"
    end

    test "switching variant resets props to variant defaults", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library/button")

      # Start on primary, switch to ghost
      html = lv |> element("button[phx-value-variant=ghost]") |> render_click()

      assert html =~ "btn-ghost"
    end

    test "changing preview width applies width class", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library/card")

      html = lv |> element("button[phx-value-width=sm]") |> render_click()

      assert html =~ "max-w-[375px]"
    end

    test "changing preview width to desktop removes width constraint", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library/card")

      lv |> element("button[phx-value-width=sm]") |> render_click()
      html = lv |> element("button[phx-value-width=full]") |> render_click()

      assert html =~ "w-full"
      refute html =~ "max-w-[375px]"
    end
  end

  # ── Node JSON view ────────────────────────────────────────────────────────────

  describe "content tree node" do
    test "node JSON is hidden by default", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _lv, html} = live(conn, ~p"/admin/ui-library/button")

      refute html =~ "&quot;type&quot;"
    end

    test "toggling node JSON reveals the content tree structure", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library/button")

      html = lv |> element("button[phx-click=toggle_node_json]") |> render_click()

      assert html =~ "name"
      assert html =~ "button"
      assert html =~ "type"
      assert html =~ "component"
      assert html =~ "props"
    end

    test "toggling again hides the node JSON", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, lv, _html} = live(conn, ~p"/admin/ui-library/button")

      lv |> element("button[phx-click=toggle_node_json]") |> render_click()
      html = lv |> element("button[phx-click=toggle_node_json]") |> render_click()

      refute html =~ "&quot;type&quot;"
    end
  end
end
