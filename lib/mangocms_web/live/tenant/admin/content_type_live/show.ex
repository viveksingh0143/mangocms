defmodule MangoCMSWeb.Tenant.Admin.ContentTypeLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.ContentEngine.ContentTypeField
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_content) do
      {:ok, socket} -> {:ok, socket}
      {:redirect, socket} -> {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    tenant = socket.assigns.current_tenant
    content_type = ContentEngine.get_content_type!(tenant, id)

    socket =
      socket
      |> assign(:content_type, content_type)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign_field(socket.assigns.live_action, params)
      |> stream_fields(content_type)

    {:noreply, socket}
  end

  defp assign_field(socket, :new_field, _params) do
    assign(socket, :field, %ContentTypeField{
      content_type_id: socket.assigns.content_type.id,
      position: next_field_position(socket)
    })
  end

  defp assign_field(socket, :edit_field, %{"field_id" => field_id}) do
    field = ContentEngine.get_content_type_field!(socket.assigns.current_tenant, field_id)
    ensure_field_belongs_to_content_type!(socket.assigns.content_type, field)
    assign(socket, :field, field)
  end

  defp assign_field(socket, :show, _params), do: assign(socket, :field, nil)

  @impl true
  def handle_info(
        {MangoCMSWeb.Tenant.Admin.ContentTypeLive.FieldFormComponent, {:saved, _field}},
        socket
      ) do
    {:noreply, stream_fields(socket, socket.assigns.content_type)}
  end

  @impl true
  def handle_event("delete_field", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    field = ContentEngine.get_content_type_field!(tenant, id)
    ensure_field_belongs_to_content_type!(socket.assigns.content_type, field)
    {:ok, _field} = ContentEngine.delete_content_type_field(tenant, field)

    {:noreply, stream_fields(socket, socket.assigns.content_type)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={@content_type.name}
      subtitle="Manage the field schema used to validate and index tenant entries."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:content}
    >
      <:actions>
        <.button
          id="back-to-content-types-button"
          navigate={~p"/admin/content-types"}
          class="btn btn-ghost"
        >
          Back
        </.button>
        <.button
          id="content-type-entries-button"
          navigate={~p"/admin/content-types/#{@content_type}/entries"}
          class="btn btn-ghost"
        >
          Entries
        </.button>
        <.button
          id="new-content-field-button"
          patch={~p"/admin/content-types/#{@content_type}/fields/new"}
          variant="primary"
        >
          <.icon name="hero-plus" class="size-4" /> New field
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new_field, :edit_field]}
        module={MangoCMSWeb.Tenant.Admin.ContentTypeLive.FieldFormComponent}
        id={@field.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        content_type={@content_type}
        field={@field}
        patch={~p"/admin/content-types/#{@content_type}"}
      />

      <section id="content-type-detail" class="mt-8 grid gap-4 lg:grid-cols-[0.8fr_1.2fr]">
        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Schema</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-base-content/60">Slug</dt>
              <dd class="font-semibold text-base-content">{@content_type.slug}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Status</dt>
              <dd class="font-medium text-base-content/90">{human_status(@content_type.status)}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Description</dt>
              <dd class="text-sm leading-6 text-base-content/80">
                {@content_type.description || "No description"}
              </dd>
            </div>
          </dl>
        </div>

        <div class="overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
          <div class="border-b border-base-300 p-5">
            <h2 class="font-semibold text-base-content">Fields</h2>
            <p class="mt-1 text-sm text-base-content/60">
              Queryable fields are projected into typed indexes for fast filters and sorts.
            </p>
          </div>

          <div id="content-type-fields" phx-update="stream" class="divide-y divide-base-300">
            <div
              id="content-type-fields-empty"
              class="hidden only:block p-10 text-center text-sm text-base-content/60"
            >
              No fields yet. Add a field to start collecting entries.
            </div>

            <div
              :for={{id, field} <- @streams.fields}
              id={id}
              class="grid gap-4 p-5 transition hover:bg-base-200 md:grid-cols-[1fr_0.8fr_auto] md:items-center"
            >
              <div>
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-semibold text-base-content">{field.label}</span>
                  <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                    {field.field_key}
                  </span>
                </div>
                <p class="mt-1 text-sm text-base-content/60">
                  {human_status(field.field_type)} · position {field.position}
                </p>
              </div>

              <div class="flex flex-wrap gap-2">
                <span :if={field.required} class={flag_class()}>Required</span>
                <span :if={field.indexed} class={flag_class()}>Indexed</span>
                <span :if={field.filterable} class={flag_class()}>Filterable</span>
                <span :if={field.sortable} class={flag_class()}>Sortable</span>
              </div>

              <div class="flex items-center gap-3 md:justify-end">
                <.link
                  id={"edit-content-field-#{field.id}"}
                  patch={~p"/admin/content-types/#{@content_type}/fields/#{field}/edit"}
                  class="btn btn-sm btn-ghost"
                >
                  Edit
                </.link>
                <button
                  id={"delete-content-field-#{field.id}"}
                  type="button"
                  phx-click="delete_field"
                  phx-value-id={field.id}
                  data-confirm="Delete this field and rebuild entry indexes?"
                  class="btn btn-sm btn-ghost text-error"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp stream_fields(socket, content_type) do
    fields = ContentEngine.list_content_type_fields(socket.assigns.current_tenant, content_type)
    stream(socket, :fields, fields, reset: true)
  end

  defp next_field_position(socket) do
    socket.assigns.current_tenant
    |> ContentEngine.list_content_type_fields(socket.assigns.content_type)
    |> Enum.map(& &1.position)
    |> case do
      [] -> 0
      positions -> Enum.max(positions) + 10
    end
  end

  defp ensure_field_belongs_to_content_type!(content_type, field) do
    if field.content_type_id != content_type.id do
      raise Ecto.NoResultsError, queryable: ContentTypeField
    end
  end

  defp page_title(:show), do: "Content type"
  defp page_title(:new_field), do: "New content field"
  defp page_title(:edit_field), do: "Edit content field"

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"

  defp flag_class do
    "rounded-full bg-primary/10 px-2.5 py-1 text-xs font-semibold text-primary"
  end
end
