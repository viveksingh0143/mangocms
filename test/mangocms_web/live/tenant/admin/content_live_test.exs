defmodule MangoCMSWeb.Tenant.Admin.ContentLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.ContentEngine

  @content_type_attrs %{
    name: "Services",
    slug: "services",
    description: "Reusable service records",
    status: "active"
  }

  @field_attrs %{
    label: "Price",
    field_key: "price",
    field_type: "number",
    required: true,
    indexed: false,
    filterable: true,
    sortable: true,
    position: 10,
    options_text: ""
  }

  defp unique_suffix, do: System.unique_integer([:positive]) |> Integer.to_string()

  defp plan_fixture(attrs \\ %{}) do
    suffix = unique_suffix()

    {:ok, plan} =
      attrs
      |> Enum.into(%{
        name: "content_admin_plan_#{suffix}",
        display_name: "Content Admin Plan #{suffix}",
        description: "For tenant content admin tests",
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
        name: "Content Admin Tenant #{suffix}",
        domain: "content-admin-#{suffix}.example",
        subdomain: "content-admin-#{suffix}",
        slug: "content_admin_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })
      |> Platform.create_tenant()

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp content_type_fixture(tenant, attrs \\ %{}) do
    suffix = unique_suffix()

    attrs =
      Enum.into(attrs, %{
        @content_type_attrs
        | name: "Services #{suffix}",
          slug: "services-#{suffix}"
      })

    {:ok, content_type} = ContentEngine.create_content_type(tenant, attrs)
    content_type
  end

  defp service_type_with_fields_fixture(tenant) do
    content_type = content_type_fixture(tenant, name: "Services", slug: "services")

    {:ok, _name_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "Name",
        field_key: "name",
        field_type: "string",
        required: true,
        indexed: true,
        position: 0
      })

    {:ok, _price_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "Price",
        field_key: "price",
        field_type: "number",
        required: true,
        filterable: true,
        sortable: true,
        position: 10
      })

    {:ok, _sale_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "On Sale",
        field_key: "on_sale",
        field_type: "boolean",
        filterable: true,
        position: 20
      })

    {:ok, _image_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "Image",
        field_key: "image_url",
        field_type: "image",
        position: 30
      })

    {:ok, _video_field} =
      ContentEngine.create_content_type_field(tenant, content_type, %{
        label: "Video",
        field_key: "video_url",
        field_type: "video",
        position: 40
      })

    content_type
  end

  defp host_conn(conn, host), do: %{conn | host: host}

  describe "content type admin" do
    test "creates, updates, and deletes content types", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/content-types")

      assert has_element?(index_live, "#new-content-type-button")
      assert index_live |> element("#new-content-type-button") |> render_click()
      assert has_element?(index_live, "#content-type-form")

      assert index_live
             |> form("#content-type-form", content_type: %{@content_type_attrs | name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#content-type-form", content_type: @content_type_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/content-types")
      content_type = ContentEngine.get_content_type_by_slug(tenant, "services")
      assert content_type.name == "Services"

      assert index_live |> element("#edit-content-type-#{content_type.id}") |> render_click()
      assert has_element?(index_live, "#content-type-form")

      assert index_live
             |> form("#content-type-form",
               content_type: %{@content_type_attrs | name: "Service Catalog"}
             )
             |> render_submit()

      assert_patch(index_live, ~p"/admin/content-types")
      assert ContentEngine.get_content_type_by_slug(tenant, "services").name == "Service Catalog"

      assert index_live |> element("#delete-content-type-#{content_type.id}") |> render_click()
      refute ContentEngine.get_content_type_by_slug(tenant, "services")
    end
  end

  describe "content field admin" do
    test "creates, updates, and deletes content type fields", %{conn: conn} do
      tenant = tenant_fixture()
      content_type = content_type_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, show_live, _html} = live(conn, ~p"/admin/content-types/#{content_type}")

      assert has_element?(show_live, "#new-content-field-button")
      assert show_live |> element("#new-content-field-button") |> render_click()
      assert has_element?(show_live, "#content-type-field-form")

      assert show_live
             |> form("#content-type-field-form", content_type_field: %{@field_attrs | label: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#content-type-field-form", content_type_field: @field_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/content-types/#{content_type}")
      [field] = ContentEngine.list_content_type_fields(tenant, content_type)
      assert field.field_key == "price"
      assert field.filterable
      assert field.sortable

      assert show_live |> element("#edit-content-field-#{field.id}") |> render_click()

      assert show_live
             |> form("#content-type-field-form",
               content_type_field: %{@field_attrs | label: "Service Price", position: 20}
             )
             |> render_submit()

      assert_patch(show_live, ~p"/admin/content-types/#{content_type}")
      [field] = ContentEngine.list_content_type_fields(tenant, content_type)
      assert field.label == "Service Price"
      assert field.position == 20

      assert show_live |> element("#delete-content-field-#{field.id}") |> render_click()
      assert ContentEngine.list_content_type_fields(tenant, content_type) == []
    end
  end

  describe "content entry admin" do
    test "creates, updates, and deletes generated content entries", %{conn: conn} do
      tenant = tenant_fixture()
      content_type = service_type_with_fields_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, entries_live, _html} = live(conn, ~p"/admin/content-types/#{content_type}/entries")

      assert has_element?(entries_live, "#new-content-entry-button")
      assert entries_live |> element("#new-content-entry-button") |> render_click()
      assert has_element?(entries_live, "#content-entry-form")
      assert has_element?(entries_live, "#content_entry_payload_image_url")
      assert has_element?(entries_live, "#content_entry_payload_image_url_upload")
      assert has_element?(entries_live, "#content_entry_payload_video_url")
      assert has_element?(entries_live, "#content_entry_payload_video_url_upload")

      invalid_entry_attrs = %{
        title: "Broken Service",
        slug: "broken-service",
        status: "published",
        payload: %{"name" => "", "price" => "not-a-number", "on_sale" => "true"}
      }

      assert entries_live
             |> form("#content-entry-form", content_entry: invalid_entry_attrs)
             |> render_change() =~ "price must be a valid number"

      valid_entry_attrs = %{
        title: "Budget Website",
        slug: "budget-website",
        status: "published",
        payload: %{"name" => "Budget Website", "price" => "99", "on_sale" => "true"}
      }

      assert entries_live
             |> form("#content-entry-form", content_entry: valid_entry_attrs)
             |> render_submit()

      assert_patch(entries_live, ~p"/admin/content-types/#{content_type}/entries")
      [entry] = ContentEngine.list_entries(tenant, content_type, status: "all")
      assert entry.title == "Budget Website"
      assert entry.payload["price"] == 99.0
      assert entry.payload["on_sale"] == true

      assert entries_live |> element("#edit-content-entry-#{entry.id}") |> render_click()

      assert entries_live
             |> form("#content-entry-form",
               content_entry: %{
                 valid_entry_attrs
                 | title: "Premium Website",
                   slug: "premium-website",
                   payload: %{"name" => "Premium Website", "price" => "299", "on_sale" => "false"}
               }
             )
             |> render_submit()

      assert_patch(entries_live, ~p"/admin/content-types/#{content_type}/entries")
      [entry] = ContentEngine.list_entries(tenant, content_type, status: "all")
      assert entry.title == "Premium Website"
      assert entry.payload["on_sale"] == false

      assert entries_live |> element("#delete-content-entry-#{entry.id}") |> render_click()
      assert ContentEngine.list_entries(tenant, content_type, status: "all") == []
    end
  end
end
