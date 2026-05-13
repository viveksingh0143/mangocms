defmodule MangoCMSWeb.Tenant.Admin.UserLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.TenantAccounts
  alias MangoCMS.TenantAccounts.User
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_users) do
      {:ok, socket} ->
        tenant = socket.assigns.current_tenant

        {:ok, stream(socket, :users, TenantAccounts.list_users(tenant))}

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
    |> assign(:page_title, "Edit tenant user")
    |> assign(:user, TenantAccounts.get_user!(socket.assigns.current_tenant, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New tenant user")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({MangoCMSWeb.Tenant.Admin.UserLive.FormComponent, {:saved, user}}, socket) do
    {:noreply, stream_insert(socket, :users, user)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    if id == socket.assigns.current_user.id do
      {:noreply, put_flash(socket, :error, "You cannot delete your own account.")}
    else
      tenant = socket.assigns.current_tenant
      user = TenantAccounts.get_user!(tenant, id)
      {:ok, _} = TenantAccounts.delete_user(tenant, user)

      {:noreply, stream_delete(socket, :users, user)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title="Tenant users"
      subtitle="Manage tenant owners, admins, staff, and member accounts in this tenant database."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:users}
    >
      <:actions>
        <.button id="new-tenant-user-button" patch={~p"/admin/users/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> New user
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Tenant.Admin.UserLive.FormComponent}
        id={@user.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        user={@user}
        patch={~p"/admin/users"}
      />

      <section class="mt-8 overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
        <div id="tenant-users" phx-update="stream" class="divide-y divide-base-300">
          <div
            id="tenant-users-empty"
            class="hidden only:block p-10 text-center text-sm text-base-content/60"
          >
            No tenant users have been created yet.
          </div>
          <div
            :for={{id, user} <- @streams.users}
            id={id}
            class="grid gap-4 p-5 transition hover:bg-base-200 lg:grid-cols-[1.3fr_0.8fr_0.8fr_auto] lg:items-center"
          >
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <span class="font-semibold text-base-content">{display_name(user)}</span>
                <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                  Tenant DB
                </span>
              </div>
              <p class="mt-1 text-sm text-base-content/60">{user.email}</p>
            </div>

            <div class="text-sm text-base-content/70">
              <p class="font-medium text-base-content/90">{role_label(user.role)}</p>
              <p>{user.locale || "en"} / {user.timezone || "UTC"}</p>
            </div>

            <div class="flex flex-wrap gap-2">
              <span class={active_status_class(user.disabled_at)}>
                {if(user.disabled_at, do: "Disabled", else: "Active")}
              </span>
              <span class={verified_status_class(user.confirmed_at)}>
                {if(user.confirmed_at, do: "Verified", else: "Unverified")}
              </span>
            </div>

            <div class="flex items-center gap-3 lg:justify-end">
              <.link
                id={"edit-tenant-user-#{user.id}"}
                patch={~p"/admin/users/#{user}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Edit
              </.link>
              <button
                id={"delete-tenant-user-#{user.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={user.id}
                data-confirm="Delete this tenant user?"
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

  defp display_name(%User{full_name: full_name}) when is_binary(full_name) do
    case String.trim(full_name) do
      "" -> "Unnamed user"
      name -> name
    end
  end

  defp display_name(_user), do: "Unnamed user"

  defp role_label(role) when is_binary(role) do
    role
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp role_label(_role), do: "Unknown"

  defp active_status_class(nil),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp active_status_class(_value),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp verified_status_class(nil),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp verified_status_class(_value),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"
end
