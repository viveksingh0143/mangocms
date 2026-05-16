defmodule MangoCMSWeb.Tenant.Admin.SectionLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.Pages
  alias MangoCMS.Tenant.Pages.Section
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_pages) do
      {:ok, socket} ->
        {:ok, stream(socket, :sections, Pages.list_sections(socket.assigns.current_tenant))}

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
    |> assign(:page_title, "Edit section")
    |> assign(:section, Pages.get_section!(socket.assigns.current_tenant, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New section")
    |> assign(:section, %Section{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Sections")
    |> assign(:section, nil)
  end

  @impl true
  def handle_info({MangoCMSWeb.Tenant.Admin.SectionLive.FormComponent, {:saved, section}}, socket) do
    {:noreply, stream_insert(socket, :sections, section)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    section = Pages.get_section!(tenant, id)
    {:ok, _section} = Pages.delete_section(tenant, section)

    {:noreply, stream_delete(socket, :sections, section)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title="Sections"
      subtitle="Manage reusable static, dynamic, and reference sections for the page builder."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:sections}
    >
      <:actions>
        <.button id="new-section-button" patch={~p"/admin/sections/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> New section
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Tenant.Admin.SectionLive.FormComponent}
        id={@section.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        current_user={@current_user}
        section={@section}
        patch={~p"/admin/sections"}
      />

      <div class="overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
        <div id="sections" phx-update="stream" class="divide-y divide-base-300">
          <div
            id="sections-empty"
            class="hidden only:block p-10 text-center text-sm text-base-content/60"
          >
            No sections have been created yet.
          </div>

          <div
            :for={{id, section} <- @streams.sections}
            id={id}
            class="grid gap-4 p-5 transition hover:bg-base-200 md:grid-cols-[1fr_auto] md:items-center"
          >
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <span class="font-semibold text-base-content">{section.name}</span>
                <span class={mode_class(section.mode)}>{section.mode}</span>
              </div>
              <p class="mt-1 text-sm text-base-content/60">
                {section.group_label} · {section.template_key}
              </p>
              <p class="mt-1 text-xs text-base-content/50">
                {loop_summary(section)}
              </p>
            </div>

            <div class="flex items-center gap-3 md:justify-end">
              <.link
                id={"build-section-#{section.id}"}
                navigate={~p"/admin/sections/#{section}/builder"}
                class="btn btn-sm btn-ghost"
              >
                Builder
              </.link>
              <.link
                id={"edit-section-#{section.id}"}
                patch={~p"/admin/sections/#{section}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Edit
              </.link>
              <button
                id={"delete-section-#{section.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={section.id}
                data-confirm="Delete this section?"
                class="btn btn-sm btn-ghost text-error"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.tenant_admin>
    """
  end

  defp mode_class("dynamic"), do: "badge badge-info"
  defp mode_class("reference"), do: "badge badge-secondary"
  defp mode_class(_mode), do: "badge badge-ghost"

  defp loop_summary(%Section{loop_settings: %{"enabled" => true, "limit" => limit}}),
    do: "Loops #{limit || "records"} records"

  defp loop_summary(_section), do: "Static content tree"
end
