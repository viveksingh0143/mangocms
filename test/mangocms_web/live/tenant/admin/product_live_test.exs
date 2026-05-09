defmodule MangoCMSWeb.Tenant.Admin.ProductLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform
  alias MangoCMS.TenantCatalog

  @product_attrs %{
    name: "Editorial Pro",
    slug: "editorial-pro",
    sku: "SKU-EDITORIAL-PRO",
    description: "A tenant-local product",
    status: "active",
    price: 99900,
    currency: "INR",
    stock_quantity: 12,
    active: true
  }

  @update_attrs %{
    name: "Editorial Scale",
    slug: "editorial-scale",
    sku: "SKU-EDITORIAL-SCALE",
    description: "Updated tenant product",
    status: "draft",
    price: 1_99900,
    currency: "USD",
    stock_quantity: 8,
    active: false
  }

  @invalid_attrs %{
    name: nil,
    slug: "Bad Slug",
    status: "draft",
    price: -1,
    currency: "INR",
    stock_quantity: -1
  }

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end

  defp plan_fixture(attrs \\ %{}) do
    suffix = unique_suffix()

    {:ok, plan} =
      attrs
      |> Enum.into(%{
        name: "growth_#{suffix}",
        display_name: "Growth #{suffix}",
        description: "For growing tenants",
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
        name: "Tenant #{suffix}",
        domain: "tenant-#{suffix}.example",
        subdomain: "tenant-#{suffix}",
        slug: "tenant_#{suffix}",
        status: "active",
        active: true,
        plan_id: plan.id
      })
      |> Platform.create_tenant()

    Platform.get_tenant_with_plan!(tenant.id)
  end

  defp product_fixture(tenant, attrs \\ %{}) do
    suffix = unique_suffix()

    product_attrs =
      Enum.into(attrs, %{
        @product_attrs
        | name: "Editorial Pro #{suffix}",
          slug: "editorial-pro-#{suffix}",
          sku: "SKU-#{suffix}"
      })

    {:ok, product} = TenantCatalog.create_product(tenant, product_attrs)

    product
  end

  defp host_conn(conn, host), do: %{conn | host: host}

  describe "tenant resolution" do
    test "resolves a tenant by custom domain and attaches it to tenant admin", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      conn = get(conn, ~p"/admin/products")

      assert html_response(conn, 200) =~ tenant.name
      assert get_session(conn, :tenant_id) == tenant.id
    end

    test "resolves a tenant by configured subdomain", %{conn: conn} do
      tenant = tenant_fixture()

      conn =
        conn
        |> host_conn("#{tenant.subdomain}.mangocms.local")
        |> register_and_log_in_tenant_user(tenant)
        |> elem(0)
        |> get(~p"/admin/products")

      assert html_response(conn, 200) =~ tenant.name
      assert get_session(conn, :tenant_id) == tenant.id
    end

    test "returns not found when no tenant matches the host", %{conn: conn} do
      conn = get(host_conn(conn, "unknown.example"), ~p"/admin/products")

      assert response(conn, 404) == "Tenant not found"
    end
  end

  describe "Index" do
    test "lists products from the current tenant database", %{conn: conn} do
      tenant = tenant_fixture()
      product = product_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _index_live, html} = live(conn, ~p"/admin/products")

      assert html =~ "Tenant products"
      assert html =~ tenant.name
      assert html =~ product.name
    end

    test "saves new product in the tenant database", %{conn: conn} do
      tenant = tenant_fixture()
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/products")

      assert index_live |> element("#new-product-button") |> render_click() =~ "New product"

      assert index_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#product-form", product: @product_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/products")
      html = render(index_live)
      assert html =~ "Editorial Pro"
      assert [%{name: "Editorial Pro"}] = TenantCatalog.list_products(tenant)
    end

    test "updates product in the current tenant database", %{conn: conn} do
      tenant = tenant_fixture()
      product = product_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/products")

      assert index_live |> element("#edit-product-#{product.id}") |> render_click() =~
               "Edit product"

      assert index_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#product-form", product: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/products")
      html = render(index_live)
      assert html =~ "Editorial Scale"
      refute html =~ product.name
    end

    test "deletes product from listing", %{conn: conn} do
      tenant = tenant_fixture()
      product = product_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)
      {:ok, index_live, _html} = live(conn, ~p"/admin/products")

      assert index_live |> element("#delete-product-#{product.id}") |> render_click()
      refute has_element?(index_live, "#products-#{product.id}")
    end

    test "keeps products isolated per tenant database", %{conn: conn} do
      tenant = tenant_fixture()
      other_tenant = tenant_fixture()
      product = product_fixture(tenant)

      {conn, _user} =
        conn
        |> host_conn(other_tenant.domain)
        |> register_and_log_in_tenant_user(other_tenant)

      {:ok, _index_live, html} = live(conn, ~p"/admin/products")

      refute html =~ product.name
      assert TenantCatalog.list_products(other_tenant) == []
    end
  end

  describe "Show" do
    test "displays product", %{conn: conn} do
      tenant = tenant_fixture()
      product = product_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, _show_live, html} = live(conn, ~p"/admin/products/#{product}")

      assert html =~ product.name
      assert html =~ "Inventory"
    end

    test "updates product within show", %{conn: conn} do
      tenant = tenant_fixture()
      product = product_fixture(tenant)
      {conn, _user} = conn |> host_conn(tenant.domain) |> register_and_log_in_tenant_user(tenant)

      {:ok, show_live, _html} = live(conn, ~p"/admin/products/#{product}")

      assert show_live |> element("#edit-product-button") |> render_click() =~ "Edit product"

      assert show_live
             |> form("#product-form", product: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/products/#{product}")
      assert render(show_live) =~ "Editorial Scale"
    end
  end
end
