defmodule MangoCMS.Tenant.PagesTest do
  use MangoCMS.DataCase

  alias MangoCMS.Platform
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

  defp content_tree_fixture(text) do
    MangoCMS.ContentTree.normalize_paths([
      %{
        "type" => "component",
        "name" => "section",
        "id" => "section_test",
        "props" => %{},
        "classes" => %{"display" => "w-full"},
        "children" => [
          %{
            "type" => "component",
            "name" => "heading",
            "id" => "heading_test",
            "props" => %{"text" => text, "level" => "1"},
            "classes" => %{"display" => "text-4xl font-bold"}
          }
        ]
      }
    ])
  end

  test "stores pages in the tenant database" do
    tenant = tenant_fixture()

    {:ok, page} =
      Pages.create_page(tenant, %{
        title: "Home",
        slug: "home",
        type: "landing",
        status: "published",
        seo: %{"description" => "Tenant home page"},
        content_tree: content_tree_fixture("Home")
      })

    published_page = Pages.get_published_page_by_slug(tenant, "home")

    assert published_page.id == page.id
    assert published_page.status == "published"
    assert published_page.published_at
    assert [%{title: "Home"}] = Pages.list_pages(tenant)
  end

  test "stores reusable sections with data source configuration" do
    tenant = tenant_fixture()
    tree = content_tree_fixture("{{title}}")

    {:ok, section} =
      Pages.create_section(tenant, %{
        name: "Product Slider",
        template_key: "slider.products",
        group_label: "Commerce",
        mode: "dynamic",
        content_tree: tree,
        source_config: %{"kind" => "product", "mappings" => %{"title" => "name"}},
        filters: %{"rules" => [%{"field" => "active", "op" => "=", "value" => true}]},
        loop_settings: %{"enabled" => true, "limit" => 8}
      })

    assert section.source_config["kind"] == "product"
    assert [%{id: id}] = Pages.list_sections(tenant)
    assert id == section.id
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

  test "saves content trees with optimistic locking and snapshots previous state" do
    tenant = tenant_fixture()
    tree = content_tree_fixture("Initial")

    {:ok, page} =
      Pages.create_page(tenant, %{
        title: "AST Page",
        slug: "ast-page",
        type: "page",
        status: "draft",
        content_tree: tree
      })

    updated_tree =
      MangoCMS.ContentTree.update_node_props(tree, "heading_test", %{"text" => "Updated"})

    assert {:ok, updated_page} =
             Pages.save_page_with_lock(
               tenant,
               page,
               %{
                 title: page.title,
                 slug: page.slug,
                 type: page.type,
                 status: page.status,
                 seo: page.seo,
                 content_tree: updated_tree
               },
               page.content_tree_version
             )

    assert updated_page.content_tree_version == page.content_tree_version + 1

    assert get_in(updated_page.content_tree, [
             Access.at(0),
             "children",
             Access.at(0),
             "props",
             "text"
           ]) == "Updated"

    assert [%{snapshot_type: "auto", content_tree: ^tree}] =
             Pages.list_page_versions(tenant, page)

    assert {:error, :stale} =
             Pages.save_page_with_lock(
               tenant,
               page,
               %{
                 title: page.title,
                 slug: page.slug,
                 type: page.type,
                 status: page.status,
                 seo: page.seo,
                 content_tree: updated_tree
               },
               page.content_tree_version
             )
  end
end
