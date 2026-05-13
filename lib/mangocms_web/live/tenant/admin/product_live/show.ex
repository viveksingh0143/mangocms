defmodule MangoCMSWeb.Tenant.Admin.ProductLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.TenantCatalog
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_products) do
      {:ok, socket} -> {:ok, socket}
      {:redirect, socket} -> {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    product = TenantCatalog.get_product!(socket.assigns.current_tenant, id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, product)}
  end

  @impl true
  def handle_info({MangoCMSWeb.Tenant.Admin.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, assign(socket, :product, product)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={@product.name}
      subtitle={"#{@current_tenant.name} tenant product"}
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:products}
    >
      <:actions>
        <.button id="back-to-products-button" navigate={~p"/admin/products"} class="btn btn-ghost">
          Back
        </.button>
        <.button
          id="edit-product-button"
          patch={~p"/admin/products/#{@product}/show/edit"}
          variant="primary"
        >
          <.icon name="hero-pencil-square" class="size-4" /> Edit
        </.button>
      </:actions>

      <.live_component
        :if={@live_action == :edit}
        module={MangoCMSWeb.Tenant.Admin.ProductLive.FormComponent}
        id={@product.id}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        product={@product}
        patch={~p"/admin/products/#{@product}"}
      />

      <section id="product-detail" class="mt-8 grid gap-4 md:grid-cols-2">
        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Catalog</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-base-content/60">Slug</dt>
              <dd class="font-semibold text-base-content">{@product.slug}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">SKU</dt>
              <dd class="font-medium text-base-content/90">{@product.sku || "None"}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Status</dt>
              <dd class="font-medium text-base-content/90">{human_status(@product.status)}</dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
            Inventory
          </h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-base-content/60">Price</dt>
              <dd class="text-lg font-semibold text-base-content">
                {@product.currency} {@product.price}
              </dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Stock</dt>
              <dd class="font-medium text-base-content/90">{@product.stock_quantity}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Visibility</dt>
              <dd class="font-medium text-base-content/90">
                {if(@product.active, do: "Visible", else: "Hidden")}
              </dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors md:col-span-2">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
            Description
          </h2>
          <p class="mt-4 text-sm leading-6 text-base-content/80">
            {@product.description || "No description"}
          </p>
        </div>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp page_title(:show), do: "Show product"
  defp page_title(:edit), do: "Edit product"

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"
end
