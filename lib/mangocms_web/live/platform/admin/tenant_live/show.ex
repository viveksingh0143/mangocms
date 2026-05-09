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
    <Layouts.admin
      flash={@flash}
      title={@tenant.name}
      subtitle={@tenant.domain}
      nav_items={Layouts.platform_admin_nav(:tenants)}
      brand_label="Platform Admin"
      brand_href={~p"/platform/admin/plans"}
      profile_name="Platform Admin"
      profile_email="platform@mangocms.local"
      profile_initials="PA"
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
        <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-500">Plan</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-slate-500">Current plan</dt>
              <dd class="text-lg font-semibold text-slate-950">{plan_name(@tenant)}</dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">Status</dt>
              <dd class="font-medium text-slate-900">{human_status(@tenant.status)}</dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">Billing cycle</dt>
              <dd class="font-medium text-slate-900">{@tenant.billing_cycle || "None"}</dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-500">Identity</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-slate-500">Slug</dt>
              <dd class="font-semibold text-slate-950">{@tenant.slug}</dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">Subdomain</dt>
              <dd class="font-medium text-slate-900">{@tenant.subdomain}</dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">Access</dt>
              <dd class="font-medium text-slate-900">
                {if(@tenant.active, do: "Active", else: "Inactive")}
              </dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm md:col-span-2">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-500">Storage</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-slate-500">Database path</dt>
              <dd class="break-all font-mono text-sm text-slate-900">{@tenant.db_path}</dd>
            </div>
            <div>
              <dt class="text-sm text-slate-500">Media path</dt>
              <dd class="break-all font-mono text-sm text-slate-900">{@tenant.storage_path}</dd>
            </div>
          </dl>
        </div>
      </section>
    </Layouts.admin>
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
