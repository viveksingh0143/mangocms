defmodule MangoCMSWeb.Platform.Admin.TenantLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Platform
  alias MangoCMS.Platform.Tenant

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :tenants, Platform.list_tenants_with_plan())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit tenant")
    |> assign(:tenant, Platform.get_tenant_with_plan!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New tenant")
    |> assign(:tenant, %Tenant{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Tenants")
    |> assign(:tenant, nil)
  end

  @impl true
  def handle_info({MangoCMSWeb.Platform.Admin.TenantLive.FormComponent, {:saved, tenant}}, socket) do
    {:noreply, stream_insert(socket, :tenants, tenant)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tenant = Platform.get_tenant_with_plan!(id)
    {:ok, _} = Platform.delete_tenant(tenant)

    {:noreply, stream_delete(socket, :tenants, tenant)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.platform_admin
      flash={@flash}
      title="Platform tenants"
      subtitle="Manage tenant domains, lifecycle state, and plan association."
      current_user={@current_user}
      active={:tenants}
    >
      <:actions>
        <.button id="new-tenant-button" patch={~p"/platform/admin/tenants/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> New tenant
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Platform.Admin.TenantLive.FormComponent}
        id={@tenant.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@tenant}
        patch={~p"/platform/admin/tenants"}
      />

      <section class="mt-8 overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
        <div id="tenants" phx-update="stream" class="divide-y divide-base-300">
          <div
            id="tenants-empty"
            class="hidden only:block p-10 text-center text-sm text-base-content/60"
          >
            No tenants have been created yet.
          </div>
          <div
            :for={{id, tenant} <- @streams.tenants}
            id={id}
            class="grid gap-4 p-5 transition hover:bg-base-200 lg:grid-cols-[1.2fr_1fr_1fr_auto] lg:items-center"
          >
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <.link
                  navigate={~p"/platform/admin/tenants/#{tenant}"}
                  class="font-semibold text-base-content hover:text-primary"
                >
                  {tenant.name}
                </.link>
                <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                  {tenant.slug}
                </span>
              </div>
              <p class="mt-1 text-sm text-base-content/60">{tenant.domain}</p>
            </div>

            <div class="text-sm text-base-content/70">
              <p class="font-medium text-base-content/90">{plan_name(tenant)}</p>
              <p>{tenant.subdomain}.mangocms.local</p>
            </div>

            <div class="flex flex-wrap gap-2">
              <span class={status_class(tenant.status)}>{human_status(tenant.status)}</span>
              <span class={active_class(tenant.active)}>
                {if(tenant.active, do: "Active", else: "Inactive")}
              </span>
            </div>

            <div class="flex items-center gap-3 lg:justify-end">
              <.link
                id={"show-tenant-#{tenant.id}"}
                navigate={~p"/platform/admin/tenants/#{tenant}"}
                class="btn btn-sm btn-ghost"
              >
                View
              </.link>
              <.link
                id={"edit-tenant-#{tenant.id}"}
                patch={~p"/platform/admin/tenants/#{tenant}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Edit
              </.link>
              <button
                id={"delete-tenant-#{tenant.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={tenant.id}
                data-confirm="Delete this tenant?"
                class="btn btn-sm btn-ghost text-error"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </section>
    </Layouts.platform_admin>
    """
  end

  defp plan_name(%Tenant{plan: %{display_name: name}}) when is_binary(name), do: name
  defp plan_name(_), do: "No plan"

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"

  defp status_class("active"),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp status_class("trialing"),
    do:
      "rounded-full bg-sky-500/10 px-2.5 py-1 text-xs font-semibold text-sky-700 dark:text-sky-300"

  defp status_class("past_due"),
    do:
      "rounded-full bg-amber-500/10 px-2.5 py-1 text-xs font-semibold text-amber-700 dark:text-amber-300"

  defp status_class("suspended"),
    do:
      "rounded-full bg-rose-500/10 px-2.5 py-1 text-xs font-semibold text-rose-700 dark:text-rose-300"

  defp status_class(_),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp active_class(true),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp active_class(false),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"
end
