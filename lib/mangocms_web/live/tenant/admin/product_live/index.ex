defmodule MangoCMSWeb.Tenant.Admin.ProductLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.Catalog, as: TenantCatalog
  alias MangoCMS.Tenant.Catalog.Product
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_products) do
      {:ok, socket} ->
        tenant = socket.assigns.current_tenant

        {:ok, stream(socket, :products, TenantCatalog.list_products(tenant))}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit product")
    |> assign(:product, TenantCatalog.get_product!(socket.assigns.current_tenant, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New product")
    |> assign(:product, %Product{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Products")
    |> assign(:product, nil)
  end

  @impl true
  def handle_info({MangoCMSWeb.Tenant.Admin.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, stream_insert(socket, :products, product)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = TenantCatalog.get_product!(socket.assigns.current_tenant, id)
    {:ok, _} = TenantCatalog.delete_product(socket.assigns.current_tenant, product)

    {:noreply, stream_delete(socket, :products, product)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title="Tenant products"
      subtitle={"#{@current_tenant.name} uses #{plan_name(@current_plan)}"}
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:products}
    >
      <:actions>
        <.button id="new-product-button" patch={~p"/admin/products/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> New product
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Tenant.Admin.ProductLive.FormComponent}
        id={@product.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        product={@product}
        patch={~p"/admin/products"}
      />

      <section class="mt-8 overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
        <div id="products" phx-update="stream" class="divide-y divide-base-300">
          <div
            id="products-empty"
            class="hidden only:block p-10 text-center text-sm text-base-content/60"
          >
            No products have been created for this tenant.
          </div>
          <div
            :for={{id, product} <- @streams.products}
            id={id}
            class="grid gap-4 p-5 transition hover:bg-base-200 lg:grid-cols-[1.4fr_0.8fr_0.8fr_auto] lg:items-center"
          >
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <.link
                  navigate={~p"/admin/products/#{product}"}
                  class="font-semibold text-base-content hover:text-primary"
                >
                  {product.name}
                </.link>
                <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                  {product.slug}
                </span>
              </div>
              <p class="mt-1 text-sm text-base-content/60">{product.sku || "No SKU"}</p>
            </div>

            <div class="text-sm text-base-content/70">
              <p class="font-medium text-base-content/90">{format_price(product)}</p>
              <p>{product.stock_quantity} in stock</p>
            </div>

            <div class="flex flex-wrap gap-2">
              <span class={status_class(product.status)}>{human_status(product.status)}</span>
              <span class={active_class(product.active)}>
                {if(product.active, do: "Visible", else: "Hidden")}
              </span>
            </div>

            <div class="flex items-center gap-3 lg:justify-end">
              <.link
                id={"show-product-#{product.id}"}
                navigate={~p"/admin/products/#{product}"}
                class="btn btn-sm btn-ghost"
              >
                View
              </.link>
              <.link
                id={"edit-product-#{product.id}"}
                patch={~p"/admin/products/#{product}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Edit
              </.link>
              <button
                id={"delete-product-#{product.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={product.id}
                data-confirm="Delete this product?"
                class="btn btn-sm btn-ghost text-error"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp plan_name(%{display_name: name}) when is_binary(name), do: name
  defp plan_name(_), do: "No plan"

  defp format_price(%Product{price: price, currency: currency}) do
    "#{currency} #{price}"
  end

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp status_class("active"),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp status_class("draft"),
    do:
      "rounded-full bg-sky-500/10 px-2.5 py-1 text-xs font-semibold text-sky-700 dark:text-sky-300"

  defp status_class("archived"),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp status_class(_),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp active_class(true),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp active_class(false),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"
end
