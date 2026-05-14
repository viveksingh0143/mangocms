defmodule MangoCMS.Tenant.PagesTest do
  use MangoCMS.DataCase

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.Pages

  defp unique_suffix, do: System.unique_integer([:positive]) |> Integer.to_string()

  defp plan_fixture do
    suffix = unique_suffix()

    {:ok, plan} =
      Platform.create_plan(%{
        name: "pages_plan_#{suffix}",
        display_name: "Pages Plan #{suffix}",
        description: "Tenant pages plan",
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
        name: "Pages Tenant #{suffix}",
        domain: "pages-#{suffix}.example",
        subdomain: "pages-#{suffix}",
        slug: "pages_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp product_type_fixture(tenant) do
    {:ok, content_type} =
      ContentEngine.create_content_type(tenant, %{
        name: "Products",
        slug: "products",
        description: "Products for dynamic page sections"
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
        filterable: true,
        sortable: true,
        position: 30
      })

    {:ok, _sale_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "On Sale",
        field_key: "on_sale",
        field_type: "boolean",
        filterable: true,
        position: 40
      })

    content_type
  end

  defp published_entry_fixture(tenant, content_type, attrs) do
    {:ok, entry} = ContentEngine.create_entry(tenant, content_type, attrs)
    {:ok, entry} = ContentEngine.publish_entry(tenant, entry)
    entry
  end

  test "stores pages and ordered sections in the tenant database" do
    tenant = tenant_fixture()

    {:ok, page} =
      Pages.create_page(tenant, %{
        title: "Home",
        slug: "home",
        type: "landing",
        status: "published",
        seo: %{"description" => "Tenant home page"}
      })

    {:ok, second_section} =
      Pages.create_section(tenant, page, %{
        type: "text",
        template_id: "default",
        mode: "fixed",
        fixed_data: %{"title" => "Second"},
        position: 20
      })

    {:ok, first_section} =
      Pages.create_section(tenant, page, %{
        type: "hero",
        template_id: "default",
        mode: "fixed",
        fixed_data: %{"title" => "First"},
        position: 10
      })

    published_page = Pages.get_published_page_by_slug(tenant, "home")

    assert published_page.status == "published"
    assert published_page.published_at
    assert Enum.map(published_page.sections, & &1.id) == [first_section.id, second_section.id]

    first_section_id = first_section.id
    second_section_id = second_section.id

    assert [%{title: "Home"}] = Pages.list_pages(tenant)

    assert [%{id: ^first_section_id}, %{id: ^second_section_id}] =
             Pages.list_sections(tenant, page)
  end

  test "does not return draft pages as public pages" do
    tenant = tenant_fixture()

    {:ok, _page} =
      Pages.create_page(tenant, %{
        title: "Draft Page",
        slug: "draft-page",
        type: "page",
        status: "draft"
      })

    refute Pages.get_published_page_by_slug(tenant, "draft-page")
  end

  test "stores dynamic section source and mappings and resolves render items" do
    tenant = tenant_fixture()
    content_type = product_type_fixture(tenant)

    featured =
      published_entry_fixture(tenant, content_type, %{
        payload: %{
          "name" => "Featured Website",
          "description" => "A polished website package",
          "price" => 149_900,
          "on_sale" => true
        }
      })

    _hidden =
      published_entry_fixture(tenant, content_type, %{
        payload: %{
          "name" => "Hidden Website",
          "description" => "Not shown by the source filter",
          "price" => 249_900,
          "on_sale" => false
        }
      })

    {:ok, page} =
      Pages.create_page(tenant, %{
        title: "Services",
        slug: "services",
        type: "landing",
        status: "published"
      })

    {:ok, section} =
      Pages.create_section_configuration(
        tenant,
        page,
        %{
          type: "feature_grid",
          template_id: "cards",
          mode: "dynamic",
          fixed_data: %{"title" => "Featured services"},
          position: 10
        },
        %{
          content_type_id: content_type.id,
          status: "published",
          filters: %{"field" => "on_sale", "op" => "==", "value" => "true"},
          sort: %{"field" => "price", "direction" => "asc"},
          limit: 3,
          offset: 0
        },
        [
          %{
            "slot" => "title",
            "source_path" => "payload.name",
            "formatter" => "text",
            "position" => 10
          },
          %{
            "slot" => "subtitle",
            "source_path" => "payload.description",
            "formatter" => "excerpt",
            "position" => 20
          },
          %{
            "slot" => "price",
            "source_path" => "payload.price",
            "formatter" => "currency",
            "position" => 30
          }
        ]
      )

    section = Pages.get_section!(tenant, section.id)
    assert section.source.content_type_id == content_type.id
    assert Enum.map(section.mappings, & &1.slot) == ["title", "subtitle", "price"]

    section_id = section.id
    assert %{^section_id => [entry]} = Pages.section_render_items(tenant, [section])
    assert entry.id == featured.id
  end
end
