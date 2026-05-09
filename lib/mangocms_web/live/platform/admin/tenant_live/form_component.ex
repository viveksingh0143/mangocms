defmodule MangoCMSWeb.Platform.Admin.TenantLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Platform

  @status_options [
    {"Trialing", "trialing"},
    {"Active", "active"},
    {"Past due", "past_due"},
    {"Cancelled", "cancelled"},
    {"Suspended", "suspended"}
  ]

  @billing_cycle_options [
    {"Monthly", "monthly"},
    {"Yearly", "yearly"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>
          Connect the tenant identity, subscription status, and assigned platform plan.
        </:subtitle>
      </.header>

      <.form for={@form} id="tenant-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:name]} type="text" label="Tenant name" placeholder="Acme Publishing" />
          <.input field={@form[:slug]} type="text" label="Storage slug" placeholder="acme" />
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <.input
            field={@form[:domain]}
            type="text"
            label="Primary domain"
            placeholder="acme.example"
          />
          <.input field={@form[:subdomain]} type="text" label="Platform subdomain" placeholder="acme" />
        </div>

        <div class="grid gap-5 md:grid-cols-3">
          <.input
            field={@form[:plan_id]}
            type="select"
            label="Plan"
            prompt="Choose a plan"
            options={@plan_options}
          />
          <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
          <.input
            field={@form[:billing_cycle]}
            type="select"
            label="Billing cycle"
            prompt="No paid cycle"
            options={@billing_cycle_options}
          />
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <.input
            field={@form[:external_customer_id]}
            type="text"
            label="External customer ID"
            placeholder="cus_..."
          />
          <.input
            field={@form[:external_subscription_id]}
            type="text"
            label="External subscription ID"
            placeholder="sub_..."
          />
        </div>

        <div class="mt-6 grid gap-3 rounded-lg border border-base-300 bg-base-200 p-4 sm:grid-cols-2 lg:grid-cols-3">
          <.input field={@form[:active]} type="checkbox" label="Active tenant" />
          <.input field={@form[:trial_used]} type="checkbox" label="Trial used" />
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-tenant-button" variant="primary" phx-disable-with="Saving...">
            Save tenant
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{tenant: tenant} = assigns, socket) do
    changeset = Platform.change_tenant_changeset(tenant)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:status_options, @status_options)
     |> assign(:billing_cycle_options, @billing_cycle_options)
     |> assign(:plan_options, plan_options())
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"tenant" => tenant_params}, socket) do
    changeset =
      socket.assigns.tenant
      |> Platform.change_tenant_changeset(tenant_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"tenant" => tenant_params}, socket) do
    save_tenant(socket, socket.assigns.action, tenant_params)
  end

  defp save_tenant(socket, :edit, tenant_params) do
    case Platform.update_tenant(socket.assigns.tenant, tenant_params) do
      {:ok, tenant} ->
        tenant = Platform.get_tenant_with_plan!(tenant.id)
        notify_parent({:saved, tenant})

        {:noreply,
         socket
         |> put_flash(:info, "Tenant updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_tenant(socket, :new, tenant_params) do
    case Platform.create_tenant(tenant_params) do
      {:ok, tenant} ->
        tenant = Platform.get_tenant_with_plan!(tenant.id)
        notify_parent({:saved, tenant})

        {:noreply,
         socket
         |> put_flash(:info, "Tenant created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp plan_options do
    Platform.list_plans()
    |> Enum.sort_by(&{&1.sort_order, &1.display_name || &1.name})
    |> Enum.map(&{&1.display_name, &1.id})
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
