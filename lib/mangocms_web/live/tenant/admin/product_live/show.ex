defmodule MangoCMSWeb.Tenant.Admin.ProductLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.TenantCatalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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
    <Layouts.admin
      flash={@flash}
      title={@product.name}
      subtitle={"#{@current_tenant.name} tenant product"}
      nav_items={Layouts.tenant_admin_nav(:products)}
      brand_label={@current_tenant.name}
      brand_href={~p"/admin/products"}
      profile_name={@current_tenant.name}
      profile_email={@current_tenant.domain}
      profile_initials="TA"
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
        <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-500">Catalog</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-slate-500">Slug</dt>
              <dd class="font-semibold text-slate-950">{@product.slug}</dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">SKU</dt>
              <dd class="font-medium text-slate-900">{@product.sku || "None"}</dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">Status</dt>
              <dd class="font-medium text-slate-900">{human_status(@product.status)}</dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-500">Inventory</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-slate-500">Price</dt>
              <dd class="text-lg font-semibold text-slate-950">
                {@product.currency} {@product.price}
              </dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">Stock</dt>
              <dd class="font-medium text-slate-900">{@product.stock_quantity}</dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">Visibility</dt>
              <dd class="font-medium text-slate-900">
                {if(@product.active, do: "Visible", else: "Hidden")}
              </dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm md:col-span-2">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-500">Description</h2>
          <p class="mt-4 text-sm leading-6 text-slate-700">
            {@product.description || "No description"}
          </p>
        </div>
      </section>
    </Layouts.admin>
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
