defmodule MangoCMSWeb.Platform.Admin.TenantLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Platform

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    tenant = Platform.get_tenant_with_plan!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tenant, tenant)}
  end

  @impl true
  def handle_info({MangoCMSWeb.Platform.Admin.TenantLive.FormComponent, {:saved, tenant}}, socket) do
    {:noreply, assign(socket, :tenant, tenant)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.platform_admin
      flash={@flash}
      title={@tenant.name}
      subtitle={@tenant.domain}
      current_user={@current_user}
      active={:tenants}
    >
      <:actions>
        <.button
          id="back-to-tenants-button"
          navigate={~p"/platform/admin/tenants"}
          class="btn btn-ghost"
        >
          Back
        </.button>
        <.button
          id="edit-tenant-button"
          patch={~p"/platform/admin/tenants/#{@tenant}/show/edit"}
          variant="primary"
        >
          <.icon name="hero-pencil-square" class="size-4" /> Edit
        </.button>
      </:actions>

      <.live_component
        :if={@live_action == :edit}
        module={MangoCMSWeb.Platform.Admin.TenantLive.FormComponent}
        id={@tenant.id}
        title={@page_title}
        action={@live_action}
        tenant={@tenant}
        patch={~p"/platform/admin/tenants/#{@tenant}"}
      />

      <section id="tenant-detail" class="mt-8 grid gap-4 md:grid-cols-2">
        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Plan</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-base-content/60">Current plan</dt>
              <dd class="text-lg font-semibold text-base-content">{plan_name(@tenant)}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Status</dt>
              <dd class="font-medium text-base-content/90">{human_status(@tenant.status)}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Billing cycle</dt>
              <dd class="font-medium text-base-content/90">{@tenant.billing_cycle || "None"}</dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Identity</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-base-content/60">Slug</dt>
              <dd class="font-semibold text-base-content">{@tenant.slug}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Subdomain</dt>
              <dd class="font-medium text-base-content/90">{@tenant.subdomain}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Access</dt>
              <dd class="font-medium text-base-content/90">
                {if(@tenant.active, do: "Active", else: "Inactive")}
              </dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors md:col-span-2">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Storage</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-base-content/60">Database path</dt>
              <dd class="break-all font-mono text-sm text-base-content/90">{@tenant.db_path}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Media path</dt>
              <dd class="break-all font-mono text-sm text-base-content/90">{@tenant.storage_path}</dd>
            </div>
          </dl>
        </div>
      </section>
    </Layouts.platform_admin>
    """
  end

  defp page_title(:show), do: "Show tenant"
  defp page_title(:edit), do: "Edit tenant"

  defp plan_name(%{plan: %{display_name: name}}) when is_binary(name), do: name
  defp plan_name(_), do: "No plan"

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"
end
