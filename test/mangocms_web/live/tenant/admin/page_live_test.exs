defmodule MangoCMSWeb.Tenant.Admin.PageLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.Pages

  @page_attrs %{
    title: "Services",
    slug: "services",
    type: "landing",
    status: "published",
    seo: %{"title" => "Services", "description" => "Services page"}
  }

  @section_attrs %{
    type: "hero",
    template_id: "default",
    mode: "fixed",
    position: 0,
    fixed_data: %{
      "eyebrow" => "Services",
      "title" => "Build better websites",
      "subtitle" => "Fixed sections render in Phase 3.",
      "cta_label" => "Contact us",
      "cta_href" => "/contact"
    }
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

  defp content_type_fixture(tenant) do
    suffix = unique_suffix()

    {:ok, content_type} =
      ContentEngine.create_content_type(tenant, %{
        name: "Services #{suffix}",
        slug: "services_#{suffix}",
        description: "Services for page source tests"
      })

    {:ok, _name_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "Name",
        field_key: "name",
        field_type: "string",
        required: true,
        indexed: true,
        position: 10
      })

    {:ok, _description_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "Description",
        field_key: "description",
        field_type: "text",
        indexed: true,
        position: 20
      })

    {:ok, _price_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "Price",
        field_key: "price",
        field_type: "number",
        sortable: true,
        position: 30
      })

    {:ok, entry} =
      ContentEngine.create_entry(tenant, content_type, %{
        title: "AI Chat Add-on",
        slug: "ai-chat-add-on",
        payload: %{
          "name" => "AI Chat Add-on",
          "description" => "Answers visitor questions from approved site content.",
          "price" => 49_900
        }
      })

    {:ok, _entry} = ContentEngine.publish_entry(tenant, entry)
    content_type
  end

  defp host_conn(conn, host), do: %{conn | host: host}

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

  describe "page sections and public render" do
    test "builder adds, selects, resizes, and reorders sections", %{conn: conn} do
      tenant = tenant_fixture()
      page = page_fixture(tenant, title: "Builder", slug: "builder")

      {:ok, first_section} =
        Pages.create_section(tenant, page, %{
          type: "hero",
          template_id: "default",
          mode: "fixed",
          fixed_data: %{"title" => "First"},
          settings: %{"width" => "full"},
          position: 10
        })

      {:ok, second_section} =
        Pages.create_section(tenant, page, %{
          type: "text",
          template_id: "default",
          mode: "fixed",
          fixed_data: %{"title" => "Second"},
          settings: %{"width" => "full"},
          position: 20
        })

      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, builder_live, _html} = live(conn, ~p"/admin/pages/#{page}/builder")

      assert has_element?(builder_live, "#page-builder")
      assert has_element?(builder_live, "#builder-page-form")
      assert has_element?(builder_live, "#builder-add-text")
      assert has_element?(builder_live, "#builder-section-form-#{first_section.id}")

      assert builder_live
             |> form("#builder-page-form",
               page: %{
                 title: "Builder Page Updated",
                 slug: page.slug,
                 type: page.type,
                 status: page.status,
                 seo: %{
                   "title" => "Builder Page Updated",
                   "subtitle" => "Inline subtitle",
                   "description" => "Builder SEO description"
                 }
               }
             )
             |> render_submit()

      page = Pages.get_page!(tenant, page.id)
      assert page.title == "Builder Page Updated"
      assert page.seo["subtitle"] == "Inline subtitle"

      assert builder_live
             |> element("#builder-section-width-half-#{first_section.id}")
             |> render_click()

      assert Pages.get_section!(tenant, first_section.id).settings["width"] == "half"

      assert builder_live
             |> element("#builder-move-down-#{first_section.id}")
             |> render_click()

      assert Enum.map(Pages.list_sections(tenant, page), & &1.id) == [
               second_section.id,
               first_section.id
             ]

      first_section = Pages.get_section!(tenant, first_section.id)

      assert builder_live
             |> form("#builder-section-form-#{first_section.id}",
               section: %{
                 type: "hero",
                 template_id: "default",
                 mode: "fixed",
                 position: first_section.position,
                 fixed_data: %{
                   "title" => "Updated builder title",
                   "subtitle" => "Updated from builder"
                 }
               }
             )
             |> render_submit()

      assert Pages.get_section!(tenant, first_section.id).fixed_data["title"] ==
               "Updated builder title"

      assert builder_live |> element("#builder-add-text") |> render_click()
      assert length(Pages.list_sections(tenant, page)) == 3
    end

    test "creates a fixed section and renders the published page by slug", %{conn: conn} do
      tenant = tenant_fixture()
      page = page_fixture(tenant, title: "Services", slug: "services")
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, show_live, _html} = live(conn, ~p"/admin/pages/#{page}")

      assert has_element?(show_live, "#new-page-section-button")
      assert show_live |> element("#new-page-section-button") |> render_click()
      assert has_element?(show_live, "#page-section-form")

      assert show_live
             |> form("#page-section-form", page_section: %{@section_attrs | template_id: ""})
             |> render_change() =~ "page-section-form"

      assert show_live
             |> form("#page-section-form", page_section: @section_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/pages/#{page}")
      [section] = Pages.list_sections(tenant, page)
      assert section.mode == "fixed"
      assert section.fixed_data["title"] == "Build better websites"

      public_conn =
        build_conn()
        |> host_conn(tenant.domain)
        |> get(~p"/services")

      assert html_response(public_conn, 200) =~ "Build better websites"
      assert html_response(public_conn, 200) =~ "Fixed sections render in Phase 3."

      assert show_live |> element("#edit-page-section-#{section.id}") |> render_click()

      assert show_live
             |> form("#page-section-form",
               page_section: %{
                 @section_attrs
                 | fixed_data: %{@section_attrs.fixed_data | "title" => "Updated hero"}
               }
             )
             |> render_submit()

      assert_patch(show_live, ~p"/admin/pages/#{page}")
      [section] = Pages.list_sections(tenant, page)
      assert section.fixed_data["title"] == "Updated hero"

      assert show_live |> element("#delete-page-section-#{section.id}") |> render_click()
      assert Pages.list_sections(tenant, page) == []
    end

    test "returns not found for draft public pages", %{conn: conn} do
      tenant = tenant_fixture()
      _page = page_fixture(tenant, title: "Draft", slug: "draft", status: "draft")

      conn =
        conn
        |> host_conn(tenant.domain)
        |> get(~p"/draft")

      assert response(conn, 404) == "Page not found"
    end

    test "creates a dynamic section with source query and mappings", %{conn: conn} do
      tenant = tenant_fixture()
      page = page_fixture(tenant, title: "Services", slug: "dynamic-services")
      content_type = content_type_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, show_live, _html} = live(conn, ~p"/admin/pages/#{page}")

      assert show_live |> element("#new-page-section-button") |> render_click()

      assert show_live
             |> form("#page-section-form",
               page_section: %{
                 type: "feature_grid",
                 template_id: "cards",
                 mode: "dynamic",
                 position: 10,
                 fixed_data: %{"title" => "Featured services"}
               }
             )
             |> render_change()

      assert has_element?(show_live, "#page-section-source-panel")

      assert show_live
             |> form("#page-section-form",
               page_section: %{
                 type: "feature_grid",
                 template_id: "cards",
                 mode: "dynamic",
                 position: 10,
                 fixed_data: %{"title" => "Featured services"},
                 source: %{
                   content_type_id: content_type.id,
                   status: "published",
                   filters: %{"field" => "", "op" => "==", "value" => ""},
                   sort: %{"field" => "price", "direction" => "desc"},
                   limit: 3,
                   offset: 0
                 },
                 mappings: %{
                   "0" => %{
                     "slot" => "eyebrow",
                     "source_path" => "",
                     "formatter" => "badge",
                     "position" => 10
                   },
                   "1" => %{
                     "slot" => "title",
                     "source_path" => "payload.name",
                     "formatter" => "text",
                     "position" => 20
                   },
                   "2" => %{
                     "slot" => "subtitle",
                     "source_path" => "payload.description",
                     "formatter" => "excerpt",
                     "position" => 30
                   },
                   "3" => %{
                     "slot" => "body",
                     "source_path" => "",
                     "formatter" => "excerpt",
                     "position" => 40
                   },
                   "4" => %{
                     "slot" => "image",
                     "source_path" => "",
                     "formatter" => "image",
                     "position" => 50
                   },
                   "5" => %{
                     "slot" => "price",
                     "source_path" => "payload.price",
                     "formatter" => "currency",
                     "position" => 60
                   },
                   "6" => %{
                     "slot" => "cta_href",
                     "source_path" => "",
                     "formatter" => "url",
                     "position" => 70
                   }
                 }
               }
             )
             |> render_submit()

      assert_patch(show_live, ~p"/admin/pages/#{page}")
      [section] = Pages.list_sections(tenant, page)
      assert section.mode == "dynamic"
      assert section.source.content_type_id == content_type.id
      assert Enum.map(section.mappings, & &1.slot) == ["title", "subtitle", "price"]

      public_conn =
        build_conn()
        |> host_conn(tenant.domain)
        |> get(~p"/dynamic-services")

      assert html_response(public_conn, 200) =~ "AI Chat Add-on"
      assert html_response(public_conn, 200) =~ "Answers visitor questions"
    end
  end
end
