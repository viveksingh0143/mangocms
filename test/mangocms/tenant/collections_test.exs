defmodule MangoCMS.Tenant.CollectionsTest do
  use MangoCMS.DataCase

  alias MangoCMS.Tenant.Collections
  alias MangoCMS.Tenant.Collections.CollectionItemIndex
  alias MangoCMS.Platform
  alias MangoCMS.Tenant.RepoManager, as: TenantRepoManager

  defp unique_suffix, do: System.unique_integer([:positive]) |> Integer.to_string()

  defp plan_fixture do
    suffix = unique_suffix()

    {:ok, plan} =
      Platform.create_plan(%{
        name: "collections_plan_#{suffix}",
        display_name: "Collections Plan #{suffix}",
        description: "Tenant content engine plan",
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
        name: "Collections Tenant #{suffix}",
        domain: "content-engine-#{suffix}.example",
        subdomain: "content-engine-#{suffix}",
        slug: "collections_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp product_type_fixture(tenant) do
    {:ok, collection} =
      Collections.create_collection(tenant, %{
        name: "Product",
        slug: "products",
        description: "Products managed through flexible collection items"
      })

    {:ok, _name_field} =
      Collections.create_collection_field(tenant, collection, %{
        label: "Name",
        field_key: "name",
        field_type: "string",
        required: true,
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
        position: 1
      })

    {:ok, _rating_field} =
      Collections.create_collection_field(tenant, collection, %{
        label: "Rating",
        field_key: "rating",
        field_type: "number",
        filterable: true,
        sortable: true,
        position: 2
      })

    {:ok, _sale_field} =
      Collections.create_collection_field(tenant, collection, %{
        label: "On Sale",
        field_key: "on_sale",
        field_type: "boolean",
        filterable: true,
        position: 3
      })

    collection
  end

  defp published_entry_fixture(tenant, collection, attrs) do
    {:ok, entry} = Collections.create_entry(tenant, collection, attrs)
    {:ok, entry} = Collections.publish_entry(tenant, entry)
    entry
  end

  test "stores flexible entries and filters through typed index projections" do
    tenant = tenant_fixture()
    collection = product_type_fixture(tenant)

    budget =
      published_entry_fixture(tenant, collection, %{
        "payload" => %{
          "name" => "Budget Website",
          "price" => 99,
          "rating" => 4.6,
          "on_sale" => true
        }
      })

    pro =
      published_entry_fixture(tenant, collection, %{
        "payload" => %{
          "name" => "Pro Website",
          "price" => 299,
          "rating" => 4.9,
          "on_sale" => true
        }
      })

    _draft =
      Collections.create_entry(tenant, collection, %{
        "payload" => %{
          "name" => "Draft Website",
          "price" => 49,
          "rating" => 5.0,
          "on_sale" => true
        }
      })

    _not_on_sale =
      published_entry_fixture(tenant, collection, %{
        "payload" => %{
          "name" => "Enterprise Website",
          "price" => 999,
          "rating" => 5.0,
          "on_sale" => false
        }
      })

    entries =
      Collections.list_entries(tenant, collection,
        filters: [
          %{"field" => "rating", "op" => ">=", "value" => 4.5},
          %{"field" => "on_sale", "op" => "==", "value" => true}
        ],
        sort: %{"field" => "price", "direction" => "asc"}
      )

    assert Enum.map(entries, & &1.id) == [budget.id, pro.id]

    index_count =
      TenantRepoManager.with_repo(tenant, fn repo ->
        repo.aggregate(CollectionItemIndex, :count)
      end)

    assert index_count >= 9
  end

  test "validates entry payloads against tenant collection fields" do
    tenant = tenant_fixture()
    collection = product_type_fixture(tenant)

    assert {:error, changeset} =
             Collections.create_entry(tenant, collection, %{
               "payload" => %{
                 "name" => "",
                 "price" => "not-a-number",
                 "rating" => 4.8,
                 "on_sale" => true
               }
             })

    assert "name is required" in errors_on(changeset).payload
    assert "price must be a valid number" in errors_on(changeset).payload
  end
end
