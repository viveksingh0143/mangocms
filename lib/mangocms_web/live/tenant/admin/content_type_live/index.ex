defmodule MangoCMSWeb.Tenant.Admin.ContentTypeLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.ContentEngine.ContentType
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_content) do
      {:ok, socket} ->
        tenant = socket.assigns.current_tenant

        {:ok, stream(socket, :content_types, ContentEngine.list_content_types(tenant))}

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
    |> assign(:page_title, "Edit content type")
    |> assign(:content_type, ContentEngine.get_content_type!(socket.assigns.current_tenant, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New content type")
    |> assign(:content_type, %ContentType{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Content types")
    |> assign(:content_type, nil)
  end

  @impl true
  def handle_info(
        {MangoCMSWeb.Tenant.Admin.ContentTypeLive.FormComponent, {:saved, content_type}},
        socket
      ) do
    {:noreply, stream_insert(socket, :content_types, content_type)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    content_type = ContentEngine.get_content_type!(tenant, id)
    {:ok, _content_type} = ContentEngine.delete_content_type(tenant, content_type)

    {:noreply, stream_delete(socket, :content_types, content_type)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title="Content types"
      subtitle="Define reusable tenant data models for dynamic pages, sections, and collections."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:content}
    >
      <:actions>
        <.button id="new-content-type-button" patch={~p"/admin/content-types/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> New content type
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Tenant.Admin.ContentTypeLive.FormComponent}
        id={@content_type.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        content_type={@content_type}
        patch={~p"/admin/content-types"}
      />

      <section class="mt-8 overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
        <div id="content-types" phx-update="stream" class="divide-y divide-base-300">
          <div
            id="content-types-empty"
            class="hidden only:block p-10 text-center text-sm text-base-content/60"
          >
            No content types have been created for this tenant.
          </div>

          <div
            :for={{id, content_type} <- @streams.content_types}
            id={id}
            class="grid gap-4 p-5 transition hover:bg-base-200 lg:grid-cols-[1.4fr_0.7fr_auto] lg:items-center"
          >
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <.link
                  navigate={~p"/admin/content-types/#{content_type}"}
                  class="font-semibold text-base-content hover:text-primary"
                >
                  {content_type.name}
                </.link>
                <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                  {content_type.slug}
                </span>
              </div>
              <p class="mt-1 text-sm text-base-content/60">
                {content_type.description || "No description"}
              </p>
            </div>

            <div>
              <span class={status_class(content_type.status)}>
                {human_status(content_type.status)}
              </span>
            </div>

            <div class="flex flex-wrap items-center gap-3 lg:justify-end">
              <.link
                id={"manage-content-type-#{content_type.id}"}
                navigate={~p"/admin/content-types/#{content_type}"}
                class="btn btn-sm btn-ghost"
              >
                Fields
              </.link>
              <.link
                id={"entries-content-type-#{content_type.id}"}
                navigate={~p"/admin/content-types/#{content_type}/entries"}
                class="btn btn-sm btn-ghost"
              >
                Entries
              </.link>
              <.link
                id={"edit-content-type-#{content_type.id}"}
                patch={~p"/admin/content-types/#{content_type}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Edit
              </.link>
              <button
                id={"delete-content-type-#{content_type.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={content_type.id}
                data-confirm="Delete this content type and all entries?"
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

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"

  defp status_class("active"),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp status_class("archived"),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp status_class(_),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"
end
