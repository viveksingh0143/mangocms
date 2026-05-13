defmodule MangoCMSWeb.Tenant.Admin.ContentEntryLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.ContentEngine.{ContentEntry, ContentTypeField}
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
    fields = ContentEngine.list_content_type_fields(tenant, content_type)

    socket =
      socket
      |> assign(:content_type, content_type)
      |> assign(:fields, fields)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign_entry(socket.assigns.live_action, params)
      |> stream_entries()

    {:noreply, socket}
  end

  defp assign_entry(socket, :new, _params) do
    assign(socket, :entry, %ContentEntry{content_type_id: socket.assigns.content_type.id})
  end

  defp assign_entry(socket, :edit, %{"entry_id" => entry_id}) do
    entry = ContentEngine.get_entry!(socket.assigns.current_tenant, entry_id)
    ensure_entry_belongs_to_content_type!(socket.assigns.content_type, entry)
    assign(socket, :entry, entry)
  end

  defp assign_entry(socket, :index, _params), do: assign(socket, :entry, nil)

  @impl true
  def handle_info(
        {MangoCMSWeb.Tenant.Admin.ContentEntryLive.FormComponent, {:saved, _entry}},
        socket
      ) do
    {:noreply, stream_entries(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    entry = ContentEngine.get_entry!(tenant, id)
    ensure_entry_belongs_to_content_type!(socket.assigns.content_type, entry)
    {:ok, _entry} = ContentEngine.delete_entry(tenant, entry)

    {:noreply, stream_delete(socket, :entries, entry)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={"#{@content_type.name} entries"}
      subtitle="Create and maintain tenant records using the fields configured for this content type."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:content}
    >
      <:actions>
        <.button
          id="back-to-content-type-button"
          navigate={~p"/admin/content-types/#{@content_type}"}
          class="btn btn-ghost"
        >
          Fields
        </.button>
        <.button
          id="new-content-entry-button"
          patch={~p"/admin/content-types/#{@content_type}/entries/new"}
          variant="primary"
        >
          <.icon name="hero-plus" class="size-4" /> New entry
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Tenant.Admin.ContentEntryLive.FormComponent}
        id={@entry.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        content_type={@content_type}
        fields={@fields}
        entry={@entry}
        patch={~p"/admin/content-types/#{@content_type}/entries"}
      />

      <section class="mt-8 overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
        <div class="border-b border-base-300 p-5">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 class="font-semibold text-base-content">Entries</h2>
              <p class="mt-1 text-sm text-base-content/60">
                Showing draft, published, and archived records for this content type.
              </p>
            </div>
            <span class="rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70">
              {length(@fields)} fields
            </span>
          </div>
        </div>

        <div id="content-entries" phx-update="stream" class="divide-y divide-base-300">
          <div
            id="content-entries-empty"
            class="hidden only:block p-10 text-center text-sm text-base-content/60"
          >
            No entries have been created for this content type.
          </div>

          <div
            :for={{id, entry} <- @streams.entries}
            id={id}
            class="grid gap-4 p-5 transition hover:bg-base-200 lg:grid-cols-[1.2fr_1fr_0.6fr_auto] lg:items-center"
          >
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <span class="font-semibold text-base-content">{entry_title(entry)}</span>
                <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                  {entry.slug}
                </span>
              </div>
              <p class="mt-1 text-sm text-base-content/60">
                {payload_preview(entry, @fields)}
              </p>
            </div>

            <div class="flex flex-wrap gap-2">
              <span
                :for={field <- preview_fields(@fields)}
                class="rounded-full bg-base-200 px-2.5 py-1 text-xs font-medium text-base-content/70"
              >
                {field.label}: {payload_value(entry, field)}
              </span>
            </div>

            <div>
              <span class={status_class(entry.status)}>{human_status(entry.status)}</span>
            </div>

            <div class="flex items-center gap-3 lg:justify-end">
              <.link
                id={"edit-content-entry-#{entry.id}"}
                patch={~p"/admin/content-types/#{@content_type}/entries/#{entry}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Edit
              </.link>
              <button
                id={"delete-content-entry-#{entry.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={entry.id}
                data-confirm="Delete this content entry?"
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

  defp stream_entries(socket) do
    entries =
      ContentEngine.list_entries(socket.assigns.current_tenant, socket.assigns.content_type,
        status: "all"
      )

    stream(socket, :entries, entries, reset: true)
  end

  defp ensure_entry_belongs_to_content_type!(content_type, entry) do
    if entry.content_type_id != content_type.id do
      raise Ecto.NoResultsError, queryable: ContentEntry
    end
  end

  defp page_title(:index), do: "Content entries"
  defp page_title(:new), do: "New content entry"
  defp page_title(:edit), do: "Edit content entry"

  defp entry_title(%ContentEntry{title: title, slug: slug}) when is_binary(title) do
    case String.trim(title) do
      "" -> slug
      value -> value
    end
  end

  defp entry_title(%ContentEntry{slug: slug}), do: slug

  defp payload_preview(%ContentEntry{payload: payload}, fields) do
    fields
    |> Enum.find_value(fn field ->
      value = Map.get(payload || %{}, field.field_key)
      if present?(value), do: format_payload_value(value), else: nil
    end)
    |> case do
      nil -> "No payload preview"
      value -> value
    end
  end

  defp preview_fields(fields), do: Enum.take(fields, 3)

  defp payload_value(%ContentEntry{payload: payload}, %ContentTypeField{} = field) do
    payload = if is_map(payload), do: payload, else: %{}

    payload
    |> Map.get(field.field_key)
    |> format_payload_value()
  end

  defp format_payload_value(value) when value in [nil, ""], do: "Empty"
  defp format_payload_value(value) when is_binary(value), do: value
  defp format_payload_value(value) when is_number(value), do: to_string(value)
  defp format_payload_value(value) when is_boolean(value), do: if(value, do: "Yes", else: "No")

  defp format_payload_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp format_payload_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp format_payload_value(%Date{} = value), do: Date.to_iso8601(value)
  defp format_payload_value(value), do: inspect(value)

  defp present?(value), do: value not in [nil, ""]

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"

  defp status_class("published"),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp status_class("draft"),
    do:
      "rounded-full bg-sky-500/10 px-2.5 py-1 text-xs font-semibold text-sky-700 dark:text-sky-300"

  defp status_class("archived"),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp status_class(_),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"
end
