defmodule MangoCMSWeb.Tenant.Admin.PageLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.Pages

  @page_attrs %{
    title: "Services",
    slug: "services",
    type: "landing",
    status: "published",
    seo: %{"title" => "Services", "description" => "Services page"}
  }

  defp unique_suffix, do: System.unique_integer([:positive]) |> Integer.to_string()

  defp plan_fixture(attrs \\ %{}) do
    suffix = unique_suffix()

    {:ok, plan} =
      attrs
      |> Enum.into(%{
        name: "page_admin_plan_#{suffix}",
        display_name: "Page Admin Plan #{suffix}",
        description: "For tenant page admin tests",
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
      |> Platform.create_plan()

    plan
  end

  defp tenant_fixture(attrs \\ %{}) do
    suffix = unique_suffix()
    plan = plan_fixture()

    {:ok, tenant} =
      attrs
      |> Enum.into(%{
        name: "Page Admin Tenant #{suffix}",
        domain: "page-admin-#{suffix}.example",
        subdomain: "page-admin-#{suffix}",
        slug: "page_admin_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })
      |> Platform.create_tenant()

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp page_fixture(tenant, attrs) do
    suffix = unique_suffix()

    attrs =
      Enum.into(attrs, %{
        @page_attrs
        | title: "Services #{suffix}",
          slug: "services-#{suffix}"
      })

    {:ok, page} = Pages.create_page(tenant, attrs)
    page
  end

  defp host_conn(conn, host, port \\ 80), do: %{conn | host: host, port: port}

  describe "page admin" do
    test "creates, updates, and deletes tenant pages", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/pages")

      assert has_element?(index_live, "#new-page-button")
      assert index_live |> element("#new-page-button") |> render_click()
      assert has_element?(index_live, "#page-form")

      assert index_live
             |> form("#page-form", page: %{@page_attrs | title: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#page-form", page: @page_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/pages")
      page = Pages.get_page_by_slug(tenant, "services")
      assert page.title == "Services"
      assert page.published_at

      assert index_live |> element("#edit-page-#{page.id}") |> render_click()

      assert index_live
             |> form("#page-form", page: %{@page_attrs | title: "Service Catalog"})
             |> render_submit()

      assert_patch(index_live, ~p"/admin/pages")
      assert Pages.get_page_by_slug(tenant, "services").title == "Service Catalog"

      assert index_live |> element("#delete-page-#{page.id}") |> render_click()
      refute Pages.get_page_by_slug(tenant, "services")
    end
  end

  describe "sections and public render" do
    test "builder edits AST content, saves snapshots, and renders the public page", %{conn: conn} do
      tenant = tenant_fixture()
      page = page_fixture(tenant, title: "Builder", slug: "builder")

      {conn, _user} =
        conn |> host_conn(tenant.domain, 4000) |> register_and_log_in_tenant_user(tenant)

      {:ok, builder_live, _html} = live(conn, ~p"/admin/pages/#{page}/builder")

      assert has_element?(builder_live, "#page-builder")
      assert has_element?(builder_live, "#ast-builder-page-form")
      assert has_element?(builder_live, "#builder-palette")
      assert has_element?(builder_live, "#builder-inspector-sidebar")
      assert has_element?(builder_live, "#editor-canvas-root")

      assert has_element?(builder_live, "[data-node-name='section']")
      assert has_element?(builder_live, "[data-node-name='row']")
      assert has_element?(builder_live, "[data-node-name='column']")
      assert has_element?(builder_live, "[data-node-name='heading']")

      assert builder_live
             |> element("[data-node-name='heading']")
             |> render_click()

      assert has_element?(builder_live, "#builder-node-inspector-form")

      assert builder_live
             |> form("#builder-node-inspector-form",
               node: %{
                 props: %{"text" => "Updated AST heading"},
                 classes: %{"display" => "text-4xl font-bold text-primary"}
               }
             )
             |> render_change()

      assert render(builder_live) =~ "Updated AST heading"
      assert has_element?(builder_live, ".text-primary")

      render_hook(builder_live, "drop_palette_node", %{
        "name" => "section",
        "variant" => "default",
        "target_id" => "root",
        "position" => "into"
      })

      assert render(builder_live) =~ "2 root blocks"

      assert builder_live
             |> form("#ast-builder-page-form",
               page: %{
                 title: "Builder Page Updated",
                 slug: page.slug,
                 status: "published",
                 seo: %{
                   "subtitle" => "Inline subtitle",
                   "description" => "Builder SEO description"
                 }
               }
             )
             |> render_submit()

      page = Pages.get_page!(tenant, page.id)
      assert page.title == "Builder Page Updated"
      assert page.seo["subtitle"] == "Inline subtitle"
      assert length(page.content_tree) == 2
      assert page.content_tree_version == 2
      assert [%{snapshot_type: "auto"}] = Pages.list_page_versions(tenant, page)

      public_conn =
        build_conn()
        |> host_conn(tenant.domain)
        |> get(~p"/builder")

      public_html = html_response(public_conn, 200)
      assert public_html =~ "Updated AST heading"
      refute public_html =~ "data-node-id"

      assert builder_live
             |> element("#builder-toggle-versions-button")
             |> render_click()

      assert builder_live
             |> form("#builder-save-version-form", version: %{label: "Before polish"})
             |> render_submit()

      assert Enum.any?(Pages.list_page_versions(tenant, page), &(&1.snapshot_type == "manual"))
    end

    test "returns not found for draft public pages", %{conn: conn} do
      tenant = tenant_fixture()
      _page = page_fixture(tenant, title: "Draft", slug: "draft", status: "draft")

      conn =
        conn
        |> host_conn(tenant.domain)
        |> get(~p"/draft")

      assert redirected_to(conn) == "/"
    end
  end
end
