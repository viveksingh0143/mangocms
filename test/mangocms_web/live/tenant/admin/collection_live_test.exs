defmodule MangoCMSWeb.Tenant.Admin.CollectionLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.Collections

  @collection_attrs %{
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
    position: 10
  }

  defp unique_suffix, do: System.unique_integer([:positive]) |> Integer.to_string()

  defp plan_fixture(attrs \\ %{}) do
    suffix = unique_suffix()

    {:ok, plan} =
      attrs
      |> Enum.into(%{
        name: "collection_admin_plan_#{suffix}",
        display_name: "Collection Admin Plan #{suffix}",
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
        name: "Collection Admin Tenant #{suffix}",
        domain: "content-admin-#{suffix}.example",
        subdomain: "content-admin-#{suffix}",
        slug: "collection_admin_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })
      |> Platform.create_tenant()

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp collection_fixture(tenant, attrs \\ %{}) do
    suffix = unique_suffix()

    attrs =
      Enum.into(attrs, %{
        @collection_attrs
        | name: "Services #{suffix}",
          slug: "services-#{suffix}"
      })

    {:ok, collection} = Collections.create_collection(tenant, attrs)
    collection
  end

  defp service_type_with_fields_fixture(tenant) do
    collection = collection_fixture(tenant, name: "Services", slug: "services")

    {:ok, _name_field} =
      Collections.create_collection_field(tenant, collection, %{
        label: "Name",
        field_key: "name",
        field_type: "string",
        required: true,
        indexed: true,
        position: 0
      })

    {:ok, _price_field} =
      Collections.create_collection_field(tenant, collection, %{
        label: "Price",
        field_key: "price",
        field_type: "number",
        required: true,
        filterable: true,
        sortable: true,
        position: 10
      })

    {:ok, _sale_field} =
      Collections.create_collection_field(tenant, collection, %{
        label: "On Sale",
        field_key: "on_sale",
        field_type: "boolean",
        filterable: true,
        position: 20
      })

    {:ok, _image_field} =
      Collections.create_collection_field(tenant, collection, %{
        label: "Image",
        field_key: "image_url",
        field_type: "image",
        position: 30
      })

    {:ok, _video_field} =
      Collections.create_collection_field(tenant, collection, %{
        label: "Video",
        field_key: "video_url",
        field_type: "video",
        position: 40
      })

    collection
  end

  defp host_conn(conn, host), do: %{conn | host: host}

  describe "collection admin" do
    test "creates, updates, and deletes collections", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/collections")

      assert has_element?(index_live, "#new-collection-button")
      assert index_live |> element("#new-collection-button") |> render_click()
      assert has_element?(index_live, "#collection-form")
      assert index_live |> element("#collection-type-content") |> render_click()
      assert index_live |> element("#collection-wizard-next") |> render_click()
      assert index_live |> element("#setup-scratch") |> render_click()
      assert index_live |> element("#collection-wizard-next") |> render_click()

      assert index_live
             |> form("#collection-form", collection: %{@collection_attrs | name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#collection-form", collection: @collection_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/collections")
      collection = Collections.get_collection_by_slug(tenant, "services")
      assert collection.name == "Services"
      assert has_element?(index_live, "#collection-card-#{collection.id}", "0 items")

      assert {:error, {:live_redirect, %{to: path}}} =
               index_live |> element("#open-collection-#{collection.id}") |> render_click()

      assert path == ~p"/admin/collections/#{collection}"
      {:ok, index_live, _html} = live(conn, ~p"/admin/collections")

      assert index_live |> element("#edit-collection-#{collection.id}") |> render_click()
      assert has_element?(index_live, "#collection-form")

      assert index_live
             |> form("#collection-form",
               collection: %{@collection_attrs | name: "Service Catalog"}
             )
             |> render_submit()

      assert_patch(index_live, ~p"/admin/collections")
      assert Collections.get_collection_by_slug(tenant, "services").name == "Service Catalog"

      assert index_live |> element("#delete-collection-#{collection.id}") |> render_click()
      assert has_element?(index_live, "#collection-confirm-modal")
      assert index_live |> element("#collection-confirm-modal button", "Delete") |> render_click()
      refute Collections.get_collection_by_slug(tenant, "services")
    end

    test "auto-generates editable collection id and starter fields", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/collections")

      assert index_live |> element("#new-collection-button") |> render_click()
      assert index_live |> element("#collection-type-content") |> render_click()
      assert index_live |> element("#collection-wizard-next") |> render_click()
      assert index_live |> element("#setup-scratch") |> render_click()
      assert index_live |> element("#collection-wizard-next") |> render_click()

      html =
        index_live
        |> form("#collection-form",
          collection: %{
            name: "Team Members",
            slug: "",
            description: "People directory",
            archetype: "content",
            item_mode: "multiple",
            environment: "live",
            status: "active",
            optional_fields: %{
              "name" => "true",
              "description" => "true",
              "cover_image" => "true"
            }
          }
        )
        |> render_change()

      assert html =~ "team_members_content"

      assert index_live
             |> form("#collection-form",
               collection: %{
                 name: "Team Members",
                 slug: "",
                 description: "People directory",
                 archetype: "content",
                 item_mode: "multiple",
                 environment: "live",
                 status: "active",
                 optional_fields: %{
                   "name" => "true",
                   "description" => "true",
                   "cover_image" => "true"
                 }
               }
             )
             |> render_submit()

      collection = Collections.get_collection_by_slug(tenant, "team_members_content")
      fields = Collections.list_collection_fields(tenant, collection)
      assert Enum.map(fields, & &1.field_key) == ["name", "description", "cover_image"]
      assert Enum.find(fields, &(&1.field_key == "name")).primary
      assert Enum.find(fields, &(&1.field_key == "name")).settings["slug_source"] == "true"
    end
  end

  describe "collection field admin" do
    test "creates, updates, and deletes collection fields", %{conn: conn} do
      tenant = tenant_fixture()
      collection = collection_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, show_live, _html} = live(conn, ~p"/admin/collections/#{collection}")

      assert show_live |> element("#manage-fields-button") |> render_click()
      assert has_element?(show_live, "#new-collection-field-button")
      assert show_live |> element("#new-collection-field-button") |> render_click()
      assert has_element?(show_live, "#collection-field-form")
      assert show_live |> element("#field-type-number") |> render_click()
      assert show_live |> element("#field-wizard-next") |> render_click()

      assert show_live
             |> form("#collection-field-form", collection_field: %{@field_attrs | label: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#collection-field-form", collection_field: @field_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/collections/#{collection}")
      [field] = Collections.list_collection_fields(tenant, collection)
      assert field.field_key == "price"
      assert field.filterable
      assert field.sortable
      assert show_live |> element("#manage-fields-button") |> render_click()
      assert has_element?(show_live, "#collection-field-#{field.id}", "Price")

      assert show_live |> element("#edit-collection-field-#{field.id}") |> render_click()
      assert show_live |> element("#field-wizard-next") |> render_click()

      assert show_live
             |> form("#collection-field-form",
               collection_field: %{@field_attrs | label: "Service Price", position: 20}
             )
             |> render_submit()

      assert_patch(show_live, ~p"/admin/collections/#{collection}")
      [field] = Collections.list_collection_fields(tenant, collection)
      assert field.label == "Service Price"
      assert field.position == 20

      assert show_live |> element("#manage-fields-button") |> render_click()
      assert has_element?(show_live, "#collection-field-#{field.id}", "Service Price")
      assert show_live |> element("#delete-collection-field-#{field.id}") |> render_click()
      assert has_element?(show_live, "#collection-confirm-modal")
      assert show_live |> element("#collection-confirm-modal button", "Delete") |> render_click()
      assert Collections.list_collection_fields(tenant, collection) == []
    end

    test "persists primary and slug source settings across field wizard steps", %{conn: conn} do
      tenant = tenant_fixture()
      collection = collection_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, show_live, _html} = live(conn, ~p"/admin/collections/#{collection}")

      assert show_live |> element("#manage-fields-button") |> render_click()
      assert show_live |> element("#new-collection-field-button") |> render_click()
      assert show_live |> element("#field-type-string") |> render_click()
      assert show_live |> element("#field-wizard-next") |> render_click()

      settings_params = %{
        label: "Name",
        field_key: "name",
        field_type: "string",
        visible: "true",
        primary: "true",
        settings: %{"slug_source" => "true"},
        position: "0"
      }

      assert show_live
             |> form("#collection-field-form", collection_field: settings_params)
             |> render_change()

      assert show_live |> element("#field-wizard-next") |> render_click()
      assert show_live |> element("#field-wizard-next") |> render_click()

      assert show_live
             |> form("#collection-field-form",
               collection_field: %{
                 field_type: "string",
                 default_value: ""
               }
             )
             |> render_submit()

      assert_patch(show_live, ~p"/admin/collections/#{collection}")
      [field] = Collections.list_collection_fields(tenant, collection)
      assert field.primary
      assert field.settings["slug_source"] == "true"

      assert show_live |> element("#manage-fields-button") |> render_click()
      assert show_live |> element("#edit-collection-field-#{field.id}") |> render_click()
      assert show_live |> element("#field-wizard-next") |> render_click()

      edit_params = %{
        label: "Display Name",
        field_key: "name",
        field_type: "string",
        visible: "true",
        primary: "false",
        settings: %{"slug_source" => "false"},
        position: "1"
      }

      assert show_live
             |> form("#collection-field-form", collection_field: edit_params)
             |> render_change()

      assert show_live |> element("#field-wizard-next") |> render_click()
      assert show_live |> element("#field-wizard-next") |> render_click()

      assert show_live
             |> form("#collection-field-form",
               collection_field: %{
                 field_type: "string",
                 default_value: ""
               }
             )
             |> render_submit()

      assert_patch(show_live, ~p"/admin/collections/#{collection}")
      [field] = Collections.list_collection_fields(tenant, collection)
      refute field.primary
      assert field.settings["slug_source"] == "false"
      assert field.label == "Display Name"
      assert field.position == 1
    end

    test "connects category fields to category collections", %{conn: conn} do
      tenant = tenant_fixture()

      category_collection =
        collection_fixture(tenant, name: "Root", slug: "root", archetype: "category")

      collection = collection_fixture(tenant, name: "Team Members", slug: "team_members")
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, show_live, _html} = live(conn, ~p"/admin/collections/#{collection}")

      assert show_live |> element("#manage-fields-button") |> render_click()
      assert show_live |> element("#new-collection-field-button") |> render_click()
      assert show_live |> element("#field-type-category") |> render_click()
      assert show_live |> element("#field-wizard-next") |> render_click()
      assert has_element?(show_live, "#collection-field-category-source")

      assert show_live
             |> form("#collection-field-form",
               collection_field: %{
                 label: "Root",
                 field_key: "root",
                 field_type: "category",
                 visible: "true",
                 settings: %{"category_collection_id" => category_collection.id},
                 position: "10"
               }
             )
             |> render_change()

      assert show_live |> element("#field-wizard-next") |> render_click()
      assert show_live |> element("#field-wizard-next") |> render_click()

      assert show_live
             |> form("#collection-field-form",
               collection_field: %{field_type: "category", default_value: ""}
             )
             |> render_submit()

      assert_patch(show_live, ~p"/admin/collections/#{collection}")
      [field] = Collections.list_collection_fields(tenant, collection)
      assert field.field_type == "category"
      assert field.settings["category_collection_id"] == category_collection.id
    end
  end

  describe "collection item admin" do
    test "creates, updates, and deletes generated collection items", %{conn: conn} do
      tenant = tenant_fixture()
      collection = service_type_with_fields_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, entries_live, _html} = live(conn, ~p"/admin/collections/#{collection}")

      assert has_element?(entries_live, "#add-collection-item-button")
      assert entries_live |> element("#add-collection-item-button") |> render_click()
      assert has_element?(entries_live, "#collection-item-form")
      assert has_element?(entries_live, "#collection_item_payload_image_url")
      assert has_element?(entries_live, "#collection_item_payload_image_url_upload")
      assert has_element?(entries_live, "#collection_item_payload_video_url")
      assert has_element?(entries_live, "#collection_item_payload_video_url_upload")

      invalid_entry_attrs = %{
        slug: "broken-service",
        status: "published",
        payload: %{"name" => "", "price" => "not-a-number", "on_sale" => "true"}
      }

      assert entries_live
             |> form("#collection-item-form", collection_item: invalid_entry_attrs)
             |> render_change() =~ "price must be a valid number"

      valid_entry_attrs = %{
        slug: "budget-website",
        status: "published",
        payload: %{"name" => "Budget Website", "price" => "99", "on_sale" => "true"}
      }

      assert entries_live
             |> form("#collection-item-form", collection_item: valid_entry_attrs)
             |> render_submit()

      assert_patch(entries_live, ~p"/admin/collections/#{collection}")
      [entry] = Collections.list_entries(tenant, collection, status: "all")
      assert entry.title == "Budget Website"
      assert entry.payload["price"] == 99.0
      assert entry.payload["on_sale"] == true

      assert has_element?(
               entries_live,
               "#inline-field-form-collection-item-#{entry.id}-price"
             )

      assert entries_live
             |> form("#inline-field-form-collection-item-#{entry.id}-price", %{
               item_id: entry.id,
               field: "price",
               value: "149"
             })
             |> render_change()

      [entry] = Collections.list_entries(tenant, collection, status: "all")
      assert entry.payload["price"] == 149.0

      assert entries_live
             |> element("#replace-image-collection-item-#{entry.id}-image_url")
             |> render_click()

      assert has_element?(entries_live, "#collection-image-modal")

      assert entries_live |> element("#edit-collection-item-#{entry.id}") |> render_click()

      assert entries_live
             |> form("#collection-item-form",
               collection_item: %{
                 valid_entry_attrs
                 | slug: "premium-website",
                   payload: %{"name" => "Premium Website", "price" => "299", "on_sale" => "false"}
               }
             )
             |> render_submit()

      assert_patch(entries_live, ~p"/admin/collections/#{collection}")
      [entry] = Collections.list_entries(tenant, collection, status: "all")
      assert entry.title == "Premium Website"
      assert entry.payload["on_sale"] == false

      assert entries_live |> element("#delete-collection-item-#{entry.id}") |> render_click()
      assert has_element?(entries_live, "#collection-confirm-modal")

      assert entries_live
             |> element("#collection-confirm-modal button", "Delete")
             |> render_click()

      assert Collections.list_entries(tenant, collection, status: "all") == []
    end

    test "adds a blank table row and saves it from row actions", %{conn: conn} do
      tenant = tenant_fixture()
      collection = service_type_with_fields_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, entries_live, _html} = live(conn, ~p"/admin/collections/#{collection}")

      assert has_element?(entries_live, "#add-draft-row-button", "Add Row")
      assert entries_live |> element("#add-draft-row-button") |> render_click()
      assert has_element?(entries_live, "#draft-collection-row")

      assert entries_live
             |> form("#draft-field-form-draft-name", field: "name", value: "Inline Service")
             |> render_change()

      assert entries_live
             |> form("#draft-field-form-draft-price", field: "price", value: "499")
             |> render_change()

      assert entries_live |> element("#save-draft-row-button") |> render_click()

      [entry] = Collections.list_entries(tenant, collection, status: "all")
      assert entry.title == "Inline Service"
      assert entry.payload["price"] == 499.0
      refute has_element?(entries_live, "#draft-collection-row")
    end

    test "updates generated slug and accepts datetime-local payload values", %{conn: conn} do
      tenant = tenant_fixture()
      collection = collection_fixture(tenant, name: "Reviews", slug: "reviews")

      {:ok, _name_field} =
        Collections.create_collection_field(tenant, collection, %{
          label: "Name",
          field_key: "name",
          field_type: "string",
          required: true,
          primary: true,
          settings: %{"slug_source" => "true"},
          position: 0
        })

      {:ok, _reviewed_at_field} =
        Collections.create_collection_field(tenant, collection, %{
          label: "Reviewed At",
          field_key: "reviewed_at",
          field_type: "datetime",
          position: 10
        })

      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, entries_live, _html} = live(conn, ~p"/admin/collections/#{collection}")

      assert entries_live |> element("#add-collection-item-button") |> render_click()

      assert entries_live
             |> form("#collection-item-form",
               collection_item: %{
                 slug: "",
                 status: "published",
                 payload: %{
                   "name" => "Prince Singh",
                   "reviewed_at" => "2026-05-17T12:59"
                 }
               }
             )
             |> render_submit()

      assert_patch(entries_live, ~p"/admin/collections/#{collection}")
      [entry] = Collections.list_entries(tenant, collection, status: "all")
      assert entry.slug == "prince-singh"
      assert entry.payload["reviewed_at"] == "2026-05-17T12:59:00"

      assert entries_live |> element("#edit-collection-item-#{entry.id}") |> render_click()

      assert entries_live
             |> form("#collection-item-form",
               collection_item: %{
                 slug: "prince-singh",
                 status: "published",
                 payload: %{
                   "name" => "Gaurav Singh",
                   "reviewed_at" => "2026-05-18T09:30"
                 }
               }
             )
             |> render_submit()

      assert_patch(entries_live, ~p"/admin/collections/#{collection}")
      [entry] = Collections.list_entries(tenant, collection, status: "all")
      assert entry.slug == "gaurav-singh"
      assert entry.payload["reviewed_at"] == "2026-05-18T09:30:00"
    end
  end
end
