defmodule MangoCMSWeb.Tenant.Admin.ContentTypeLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.ContentEngine.{ContentEntry, ContentTypeField}
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_content) do
      {:ok, socket} ->
        {:ok,
         socket
         |> assign(:collection_layout, "table")
         |> assign(:filters_open?, false)
         |> assign(:sorts_open?, false)}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id} = params, url, socket) do
    tenant = socket.assigns.current_tenant
    content_type = ContentEngine.get_content_type!(tenant, id)

    socket =
      socket
      |> assign(:collection_base_path, collection_base_path(url))
      |> assign(:content_type, content_type)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:manage_fields_open?, false)
      |> assign_action_resource(socket.assigns.live_action, params)
      |> stream_fields(content_type)
      |> assign_entries(content_type)

    {:noreply, socket}
  end

  defp assign_action_resource(socket, :new_field, _params) do
    socket
    |> assign(:field, %ContentTypeField{
      content_type_id: socket.assigns.content_type.id,
      position: next_field_position(socket)
    })
    |> assign(:entry, nil)
  end

  defp assign_action_resource(socket, :edit_field, %{"field_id" => field_id}) do
    field = ContentEngine.get_content_type_field!(socket.assigns.current_tenant, field_id)
    ensure_field_belongs_to_content_type!(socket.assigns.content_type, field)

    socket
    |> assign(:field, field)
    |> assign(:entry, nil)
  end

  defp assign_action_resource(socket, :new_entry, _params) do
    socket
    |> assign(:field, nil)
    |> assign(:entry, %ContentEntry{content_type_id: socket.assigns.content_type.id})
  end

  defp assign_action_resource(socket, :edit_entry, %{"entry_id" => entry_id}) do
    entry = ContentEngine.get_entry!(socket.assigns.current_tenant, entry_id)
    ensure_entry_belongs_to_content_type!(socket.assigns.content_type, entry)

    socket
    |> assign(:field, nil)
    |> assign(:entry, entry)
  end

  defp assign_action_resource(socket, :show, _params) do
    socket
    |> assign(:field, nil)
    |> assign(:entry, nil)
  end

  @impl true
  def handle_info(
        {MangoCMSWeb.Tenant.Admin.ContentTypeLive.FieldFormComponent, {:saved, _field}},
        socket
      ) do
    {:noreply, stream_fields(socket, socket.assigns.content_type)}
  end

  @impl true
  def handle_info(
        {MangoCMSWeb.Tenant.Admin.ContentEntryLive.FormComponent, {:saved, _entry}},
        socket
      ) do
    {:noreply, assign_entries(socket, socket.assigns.content_type)}
  end

  @impl true
  def handle_event("delete_field", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    field = ContentEngine.get_content_type_field!(tenant, id)
    ensure_field_belongs_to_content_type!(socket.assigns.content_type, field)

    if field.system do
      raise Ecto.NoResultsError, queryable: ContentTypeField
    end

    {:ok, _field} = ContentEngine.delete_content_type_field(tenant, field)

    {:noreply, stream_fields(socket, socket.assigns.content_type)}
  end

  def handle_event("toggle_manage_fields", _params, socket) do
    {:noreply, update(socket, :manage_fields_open?, &(!&1))}
  end

  def handle_event("toggle_field_visibility", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    field = ContentEngine.get_content_type_field!(tenant, id)
    ensure_field_belongs_to_content_type!(socket.assigns.content_type, field)

    if field.system do
      {:noreply, socket}
    else
      {:ok, _field} =
        ContentEngine.update_content_type_field(tenant, field, %{visible: !field.visible})

      {:noreply, stream_fields(socket, socket.assigns.content_type)}
    end
  end

  def handle_event("set_collection_layout", %{"layout" => layout}, socket)
      when layout in ~w(table list gallery) do
    {:noreply, assign(socket, :collection_layout, layout)}
  end

  def handle_event("toggle_filters", _params, socket) do
    {:noreply, update(socket, :filters_open?, &(!&1))}
  end

  def handle_event("toggle_sorts", _params, socket) do
    {:noreply, update(socket, :sorts_open?, &(!&1))}
  end

  def handle_event("delete_entry", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    entry = ContentEngine.get_entry!(tenant, id)
    ensure_entry_belongs_to_content_type!(socket.assigns.content_type, entry)
    {:ok, _entry} = ContentEngine.delete_entry(tenant, entry)

    {:noreply, assign_entries(socket, socket.assigns.content_type)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={@content_type.name}
      subtitle="Collection workspace for items, schema fields, and environment-specific content."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:content}
    >
      <:actions>
        <.button
          id="back-to-collections-button"
          navigate={@collection_base_path}
          class="btn btn-ghost"
        >
          Back
        </.button>
        <.button
          id="add-collection-item-button"
          patch={"#{@collection_base_path}/#{@content_type.id}/items/new"}
          variant="primary"
        >
          <.icon name="hero-plus" class="size-4" /> Add Item
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
        patch={"#{@collection_base_path}/#{@content_type.id}"}
      />

      <.live_component
        :if={@live_action in [:new_entry, :edit_entry]}
        module={MangoCMSWeb.Tenant.Admin.ContentEntryLive.FormComponent}
        id={@entry.id || :new}
        title={@page_title}
        action={entry_action(@live_action)}
        tenant={@current_tenant}
        current_user={@current_user}
        content_type={@content_type}
        fields={@fields}
        entry={@entry}
        patch={"#{@collection_base_path}/#{@content_type.id}"}
      />

      <section id="collection-workspace">
        <div class="overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
          <div class="flex flex-wrap items-center justify-between gap-3 border-b border-base-300 p-4">
            <div class="flex flex-wrap items-center gap-3">
              <h2 class="text-lg font-semibold">Default view</h2>
              <div class="dropdown">
                <button tabindex="0" type="button" class="btn btn-sm btn-outline rounded-full">
                  <.icon name={layout_icon(@collection_layout)} class="size-4" />
                  {human_status(@collection_layout)}
                  <.icon name="hero-chevron-down" class="size-4" />
                </button>
                <ul
                  tabindex="0"
                  class="menu dropdown-content z-20 mt-2 w-48 rounded-lg border border-base-300 bg-base-100 p-2 shadow-xl"
                >
                  <li class="menu-title">Choose layout</li>
                  <li :for={layout <- ~w(table list gallery)}>
                    <button
                      type="button"
                      phx-click="set_collection_layout"
                      phx-value-layout={layout}
                      class={@collection_layout == layout && "active"}
                    >
                      <.icon name={layout_icon(layout)} class="size-4" /> {human_status(layout)}
                    </button>
                  </li>
                </ul>
              </div>
              <button class="btn btn-sm btn-ghost text-base-content/40" disabled>
                <.icon name="hero-arrow-path" class="size-4" /> Refresh order
              </button>
            </div>

            <div class="flex flex-wrap items-center gap-2">
              <button
                id="manage-fields-button"
                type="button"
                phx-click="toggle_manage_fields"
                class="btn btn-sm btn-outline rounded-full"
              >
                Manage Fields
              </button>
              <div class="relative">
                <button
                  id="sort-items-button"
                  type="button"
                  phx-click="toggle_sorts"
                  class="btn btn-sm btn-outline rounded-full"
                >
                  Sort <span class="badge badge-sm">1</span>
                </button>
                <div
                  :if={@sorts_open?}
                  id="sort-popover"
                  class="absolute right-0 z-30 mt-3 w-72 rounded-lg border border-base-300 bg-base-100 p-4 shadow-xl"
                >
                  <p class="font-semibold">Sort</p>
                  <p class="mt-2 text-sm text-base-content/60">Created At, newest first</p>
                </div>
              </div>
              <div class="relative">
                <button
                  id="filter-items-button"
                  type="button"
                  phx-click="toggle_filters"
                  class="btn btn-sm btn-outline rounded-full"
                >
                  Filter <span class="badge badge-sm">2</span>
                </button>
                <div
                  :if={@filters_open?}
                  id="filter-popover"
                  class="absolute right-0 z-30 mt-3 w-96 rounded-lg border border-base-300 bg-base-100 shadow-xl"
                >
                  <div class="border-b border-base-300 p-4">
                    <p class="font-semibold">Name</p>
                    <p class="text-sm text-base-content/60">Contains pressure</p>
                  </div>
                  <div class="border-b border-base-300 p-4">
                    <p class="font-semibold">Status</p>
                    <p class="text-sm text-base-content/60">Is published</p>
                  </div>
                  <button class="btn btn-ghost m-3 text-primary">
                    <.icon name="hero-plus" class="size-4" /> New Filter
                  </button>
                </div>
              </div>
              <button class="btn btn-sm btn-outline rounded-full">Apply Order to Site</button>
              <label class="input input-bordered input-sm flex min-w-64 items-center gap-2 rounded-full">
                <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
                <input type="search" placeholder="Search" class="grow" />
              </label>
              <div class="join">
                <button class="btn join-item btn-sm btn-active">Live</button>
                <button class="btn join-item btn-sm">Sandbox</button>
              </div>
              <div class="dropdown dropdown-end">
                <button tabindex="0" type="button" class="btn btn-sm btn-outline rounded-full">
                  More Actions <.icon name="hero-chevron-down" class="size-4" />
                </button>
                <ul
                  tabindex="0"
                  class="menu dropdown-content z-20 mt-2 w-72 rounded-lg border border-base-300 bg-base-100 p-2 shadow-xl"
                >
                  <li>
                    <button><.icon name="hero-arrow-down-tray" class="size-4" /> Import items</button>
                  </li>
                  <li>
                    <button><.icon name="hero-arrow-up-tray" class="size-4" /> Export to CSV</button>
                  </li>
                  <li>
                    <button>
                      <.icon name="hero-cog-6-tooth" class="size-4" /> Collection settings
                    </button>
                  </li>
                  <li>
                    <button><.icon name="hero-key" class="size-4" /> Permissions & privacy</button>
                  </li>
                  <li>
                    <button>
                      <.icon name="hero-chat-bubble-left" class="size-4" /> Submit feedback
                    </button>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          <div :if={@collection_layout == "table"} class="overflow-x-auto">
            <table id="collection-ledger-table" class="table table-zebra">
              <thead>
                <tr>
                  <th><input type="checkbox" class="checkbox checkbox-sm" /></th>
                  <th :for={field <- visible_fields(@fields)}>{field.label}</th>
                  <th>Slug</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr :for={entry <- @entries}>
                  <td><input type="checkbox" class="checkbox checkbox-sm" /></td>
                  <td :for={field <- visible_fields(@fields)}>
                    {entry_field_value(entry, field)}
                  </td>
                  <td>{entry.slug}</td>
                  <td>
                    <span class={status_class(entry.status)}>{human_status(entry.status)}</span>
                  </td>
                  <td>
                    <.link
                      id={"edit-content-entry-#{entry.id}"}
                      patch={"#{@collection_base_path}/#{@content_type.id}/items/#{entry.id}/edit"}
                      class="btn btn-xs btn-ghost"
                    >
                      Edit
                    </.link>
                    <button
                      id={"delete-content-entry-#{entry.id}"}
                      type="button"
                      phx-click="delete_entry"
                      phx-value-id={entry.id}
                      data-confirm="Delete this collection item?"
                      class="btn btn-xs btn-ghost text-error"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
                <tr>
                  <td colspan={length(visible_fields(@fields)) + 4}>
                    <.link
                      patch={"#{@collection_base_path}/#{@content_type.id}/items/new"}
                      class="btn btn-ghost text-primary"
                    >
                      <.icon name="hero-plus" class="size-4" /> Add Item
                    </.link>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div
            :if={@collection_layout == "list"}
            id="collection-list-layout"
            class="divide-y divide-base-300"
          >
            <div
              :for={entry <- @entries}
              class="grid gap-4 p-5 md:grid-cols-[1fr_auto] md:items-center"
            >
              <div>
                <p class="font-semibold">{entry_title(entry, @fields)}</p>
                <p class="mt-1 text-sm text-base-content/60">{entry.slug}</p>
              </div>
              <span class={status_class(entry.status)}>{human_status(entry.status)}</span>
            </div>
          </div>

          <div
            :if={@collection_layout == "gallery"}
            id="collection-gallery-layout"
            class="grid gap-4 p-5 sm:grid-cols-2 lg:grid-cols-4"
          >
            <div
              :for={entry <- @entries}
              class="overflow-hidden rounded-lg border border-base-300 bg-base-100"
            >
              <div class="flex aspect-video items-center justify-center bg-base-200">
                <img
                  :if={entry_image(entry, @fields)}
                  src={entry_image(entry, @fields)}
                  alt=""
                  class="h-full w-full object-cover"
                />
                <.icon
                  :if={!entry_image(entry, @fields)}
                  name="hero-photo"
                  class="size-8 text-base-content/40"
                />
              </div>
              <div class="p-4">
                <p class="font-semibold">{entry_title(entry, @fields)}</p>
                <p class="mt-1 text-sm text-base-content/60">{entry.slug}</p>
              </div>
            </div>
            <.link
              patch={"#{@collection_base_path}/#{@content_type.id}/items/new"}
              class="flex min-h-48 flex-col items-center justify-center rounded-lg border border-dashed border-base-300 text-primary"
            >
              <.icon name="hero-plus" class="size-7" /> Add Item
            </.link>
          </div>
        </div>

        <aside
          :if={@manage_fields_open?}
          id="manage-fields-drawer"
          class="fixed bottom-0 right-0 top-36 z-40 flex w-[28rem] min-h-0 flex-col overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-2xl"
        >
          <div class="sticky top-0 z-10 flex items-start justify-between border-b border-base-300 bg-base-100 p-4">
            <div>
              <h2 class="font-semibold">Manage Fields</h2>
              <p class="mt-1 text-sm text-base-content/60">Modify visibility, types, and rules.</p>
            </div>
            <button
              id="close-manage-fields-button"
              type="button"
              phx-click="toggle_manage_fields"
              class="btn btn-ghost btn-sm btn-circle"
            >
              <.icon name="hero-x-mark" class="size-4" />
            </button>
          </div>

          <div id="content-type-fields" class="min-h-0 flex-1 overflow-y-auto">
            <div
              :for={field <- @fields}
              id={"content-type-field-#{field.id}"}
              class="grid grid-cols-[auto_auto_auto_1fr_auto] items-center gap-3 border-b border-base-300 p-3 transition hover:bg-base-200"
            >
              <span class="cursor-grab text-base-content/40">::</span>
              <button
                type="button"
                phx-click="toggle_field_visibility"
                phx-value-id={field.id}
                disabled={field.system}
                class="btn btn-ghost btn-xs btn-circle"
              >
                <.icon
                  name={if(field.visible, do: "hero-eye", else: "hero-eye-slash")}
                  class="size-4"
                />
              </button>
              <span class="badge badge-ghost">{field_icon(field)}</span>
              <div>
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-semibold text-base-content">{field.label}</span>
                  <span :if={field.primary} class="badge badge-primary badge-sm">Primary</span>
                  <span :if={field.system} class="badge badge-ghost badge-sm">System</span>
                </div>
                <p class="mt-1 text-xs text-base-content/60">
                  {field.field_key} · {human_status(field.field_type)}
                </p>
              </div>
              <div class="dropdown dropdown-end">
                <button type="button" tabindex="0" class="btn btn-ghost btn-xs btn-circle">
                  <.icon name="hero-ellipsis-horizontal" class="size-4" />
                </button>
                <ul
                  tabindex="0"
                  class="menu dropdown-content z-20 mt-2 w-56 rounded-lg border border-base-300 bg-base-100 p-2 shadow-xl"
                >
                  <li>
                    <.link
                      id={"edit-content-field-#{field.id}"}
                      patch={"#{@collection_base_path}/#{@content_type.id}/fields/#{field.id}/edit"}
                    >
                      Edit
                    </.link>
                  </li>
                  <li>
                    <button disabled={
                      field.primary or
                        not ContentTypeField.primary_field_type?(field.field_type)
                    }>
                      Make primary
                    </button>
                  </li>
                  <li><button disabled={field.system}>Duplicate field</button></li>
                  <li><button disabled={field.system}>Duplicate with content</button></li>
                  <li>
                    <button
                      id={"delete-content-field-#{field.id}"}
                      type="button"
                      phx-click="delete_field"
                      phx-value-id={field.id}
                      disabled={field.system}
                      data-confirm="Delete this field and rebuild entry indexes?"
                      class="text-error"
                    >
                      Delete
                    </button>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          <div class="sticky bottom-0 border-t border-base-300 bg-base-100 p-3">
            <.button
              id="new-content-field-button"
              patch={"#{@collection_base_path}/#{@content_type.id}/fields/new"}
              class="btn btn-primary w-full"
            >
              <.icon name="hero-plus" class="size-4" /> Add New Field
            </.button>
          </div>
        </aside>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp stream_fields(socket, content_type) do
    fields = ContentEngine.list_content_type_fields(socket.assigns.current_tenant, content_type)

    socket
    |> assign(:fields, fields)
    |> stream(:fields, fields, reset: true)
  end

  defp assign_entries(socket, content_type) do
    entries =
      ContentEngine.list_entries(socket.assigns.current_tenant, content_type, status: "all")

    assign(socket, :entries, entries)
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

  defp ensure_entry_belongs_to_content_type!(content_type, entry) do
    if entry.content_type_id != content_type.id do
      raise Ecto.NoResultsError, queryable: ContentEntry
    end
  end

  defp page_title(:show), do: "Collection"
  defp page_title(:new_field), do: "Add a field"
  defp page_title(:edit_field), do: "Edit field"
  defp page_title(:new_entry), do: "New collection item"
  defp page_title(:edit_entry), do: "Edit collection item"

  defp entry_action(:new_entry), do: :new
  defp entry_action(:edit_entry), do: :edit

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"

  defp visible_fields(fields), do: Enum.filter(fields, & &1.visible)
  defp field_icon(%{field_type: type}), do: type |> String.first() |> String.upcase()

  defp layout_icon("list"), do: "hero-bars-3-bottom-left"
  defp layout_icon("gallery"), do: "hero-squares-2x2"
  defp layout_icon(_layout), do: "hero-table-cells"

  defp entry_field_value(%ContentEntry{payload: payload}, %ContentTypeField{} = field) do
    payload = if is_map(payload), do: payload, else: %{}

    payload
    |> Map.get(field.field_key)
    |> format_value()
  end

  defp entry_title(%ContentEntry{title: title}, _fields) when is_binary(title) and title != "",
    do: title

  defp entry_title(%ContentEntry{} = entry, fields) do
    case Enum.find(fields, & &1.primary) do
      nil -> entry.slug
      field -> entry_field_value(entry, field)
    end
  end

  defp entry_image(%ContentEntry{payload: payload}, fields) do
    field = Enum.find(fields, &(&1.field_type in ~w(image gallery)))
    payload = if is_map(payload), do: payload, else: %{}

    case field && Map.get(payload, field.field_key) do
      [url | _rest] when is_binary(url) -> url
      url when is_binary(url) and url != "" -> url
      _other -> nil
    end
  end

  defp format_value(value) when value in [nil, ""], do: "..."
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_number(value), do: to_string(value)
  defp format_value(value) when is_boolean(value), do: if(value, do: "Yes", else: "No")
  defp format_value(value) when is_list(value), do: Enum.join(value, ", ")
  defp format_value(value), do: inspect(value)

  defp status_class("published"), do: "badge badge-success"
  defp status_class("archived"), do: "badge badge-ghost"
  defp status_class(_status), do: "badge badge-warning"

  defp collection_base_path(url) when is_binary(url) do
    if String.contains?(url, "/admin/collections"),
      do: "/admin/collections",
      else: "/admin/collections"
  end
end
