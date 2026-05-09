defmodule MangoCMSWeb.Tenant.Admin.ProductLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.TenantCatalog

  @status_options [
    {"Draft", "draft"},
    {"Active", "active"},
    {"Archived", "archived"}
  ]

  @currency_options [
    {"INR", "INR"},
    {"USD", "USD"},
    {"EUR", "EUR"},
    {"GBP", "GBP"},
    {"AUD", "AUD"},
    {"SGD", "SGD"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>Products are stored inside the isolated tenant database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="product-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:name]} type="text" label="Product name" placeholder="Editorial Pro" />
          <.input field={@form[:slug]} type="text" label="Slug" placeholder="editorial-pro" />
        </div>

        <div class="grid gap-5 md:grid-cols-3">
          <.input field={@form[:sku]} type="text" label="SKU" placeholder="SKU-1001" />
          <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
          <.input field={@form[:currency]} type="select" label="Currency" options={@currency_options} />
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:price]} type="number" label="Price" min="0" />
          <.input field={@form[:stock_quantity]} type="number" label="Stock quantity" min="0" />
        </div>

        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          rows="3"
          placeholder="Short product description."
        />

        <div class="mt-6 rounded-lg border border-base-300 bg-base-200 p-4">
          <.input field={@form[:active]} type="checkbox" label="Visible in tenant catalog" />
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-product-button" variant="primary" phx-disable-with="Saving...">
            Save product
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    changeset = TenantCatalog.change_product(product)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:status_options, @status_options)
     |> assign(:currency_options, @currency_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> TenantCatalog.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, product_params) do
    case TenantCatalog.update_product(
           socket.assigns.tenant,
           socket.assigns.product,
           product_params
         ) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_product(socket, :new, product_params) do
    case TenantCatalog.create_product(socket.assigns.tenant, product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
