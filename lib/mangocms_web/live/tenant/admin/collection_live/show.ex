defmodule MangoCMSWeb.Tenant.Admin.CollectionLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.Collections
  alias MangoCMS.Tenant.Collections.{CollectionItem, CollectionField}
  alias MangoCMS.Uploads
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_content) do
      {:ok, socket} ->
        {:ok,
         socket
         |> assign(:collection_layout, "table")
         |> assign(:item_query, "")
         |> assign(:item_sorts, [%{"field" => "inserted_at", "direction" => "desc"}])
         |> assign(:sort_editor, nil)
         |> assign(:item_filters, [])
         |> assign(:filter_editor, nil)
         |> assign(:filters_open?, false)
         |> assign(:sorts_open?, false)
         |> assign(:image_modal, nil)
         |> assign(:image_url_modal, nil)
         |> allow_upload(:inline_image,
           accept: ~w(.jpg .jpeg .png .gif .webp .svg),
           max_entries: 1,
           max_file_size: 5_000_000,
           auto_upload: true
         )}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id} = params, url, socket) do
    tenant = socket.assigns.current_tenant
    collection = Collections.get_collection!(tenant, id)

    socket =
      socket
      |> assign(:collection_base_path, collection_base_path(url))
      |> assign(:collection, collection)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:manage_fields_open?, false)
      |> assign_action_resource(socket.assigns.live_action, params)
      |> stream_fields(collection)
      |> assign_entries(collection)

    {:noreply, socket}
  end

  defp assign_action_resource(socket, :new_field, _params) do
    socket
    |> assign(:field, %CollectionField{
      collection_id: socket.assigns.collection.id,
      position: next_field_position(socket)
    })
    |> assign(:entry, nil)
  end

  defp assign_action_resource(socket, :edit_field, %{"field_id" => field_id}) do
    field = Collections.get_collection_field!(socket.assigns.current_tenant, field_id)
    ensure_field_belongs_to_collection!(socket.assigns.collection, field)

    socket
    |> assign(:field, field)
    |> assign(:entry, nil)
  end

  defp assign_action_resource(socket, :new_entry, _params) do
    socket
    |> assign(:field, nil)
    |> assign(:entry, %CollectionItem{collection_id: socket.assigns.collection.id})
  end

  defp assign_action_resource(socket, :edit_entry, %{"entry_id" => entry_id}) do
    entry = Collections.get_entry!(socket.assigns.current_tenant, entry_id)
    ensure_entry_belongs_to_collection!(socket.assigns.collection, entry)

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
        {MangoCMSWeb.Tenant.Admin.CollectionLive.FieldFormComponent, {:saved, _field}},
        socket
      ) do
    {:noreply, stream_fields(socket, socket.assigns.collection)}
  end

  @impl true
  def handle_info(
        {MangoCMSWeb.Tenant.Admin.CollectionItemLive.FormComponent, {:saved, _entry}},
        socket
      ) do
    {:noreply, assign_entries(socket, socket.assigns.collection)}
  end

  @impl true
  def handle_event("delete_field", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    field = Collections.get_collection_field!(tenant, id)
    ensure_field_belongs_to_collection!(socket.assigns.collection, field)

    if field.system do
      raise Ecto.NoResultsError, queryable: CollectionField
    end

    {:ok, _field} = Collections.delete_collection_field(tenant, field)

    {:noreply, stream_fields(socket, socket.assigns.collection)}
  end

  def handle_event("toggle_manage_fields", _params, socket) do
    {:noreply, update(socket, :manage_fields_open?, &(!&1))}
  end

  def handle_event("toggle_field_visibility", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    field = Collections.get_collection_field!(tenant, id)
    ensure_field_belongs_to_collection!(socket.assigns.collection, field)

    if field.system do
      {:noreply, socket}
    else
      {:ok, _field} =
        Collections.update_collection_field(tenant, field, %{visible: !field.visible})

      {:noreply, stream_fields(socket, socket.assigns.collection)}
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

  def handle_event("refresh_items", _params, socket) do
    {:noreply,
     socket
     |> assign_entries(socket.assigns.collection)
     |> put_flash(:info, "Items refreshed successfully.")}
  end

  def handle_event("search_items", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:item_query, query)
     |> assign_entries(socket.assigns.collection)}
  end

  def handle_event("open_sort_form", params, socket) do
    index = sort_index(params["index"])
    sort = if is_integer(index), do: Enum.at(socket.assigns.item_sorts, index), else: nil

    {:noreply,
     assign(socket, :sort_editor, %{
       index: index,
       field: (sort && sort["field"]) || "title",
       direction: (sort && sort["direction"]) || "asc"
     })}
  end

  def handle_event("close_sort_form", _params, socket) do
    {:noreply, assign(socket, :sort_editor, nil)}
  end

  def handle_event(
        "save_sort",
        %{"sort" => %{"field" => field, "direction" => direction}},
        socket
      )
      when direction in ~w(asc desc) do
    sort = %{"field" => field, "direction" => direction}
    index = socket.assigns.sort_editor && socket.assigns.sort_editor.index

    sorts =
      if is_integer(index) do
        List.replace_at(socket.assigns.item_sorts, index, sort)
      else
        socket.assigns.item_sorts ++ [sort]
      end

    {:noreply,
     socket
     |> assign(:item_sorts, sorts)
     |> assign(:sort_editor, nil)
     |> assign_entries(socket.assigns.collection)}
  end

  def handle_event("delete_sort", %{"index" => index}, socket) do
    index = sort_index(index)

    sorts =
      if is_integer(index),
        do: List.delete_at(socket.assigns.item_sorts, index),
        else: socket.assigns.item_sorts

    {:noreply,
     socket
     |> assign(:item_sorts, sorts)
     |> assign(:sort_editor, nil)
     |> assign_entries(socket.assigns.collection)}
  end

  def handle_event("open_filter_form", params, socket) do
    index = sort_index(params["index"])
    filter = if is_integer(index), do: Enum.at(socket.assigns.item_filters, index), else: nil

    {:noreply,
     assign(socket, :filter_editor, %{
       index: index,
       field: (filter && filter["field"]) || "title",
       condition: (filter && filter["condition"]) || "is",
       value: (filter && filter["value"]) || ""
     })}
  end

  def handle_event("close_filter_form", _params, socket) do
    {:noreply, assign(socket, :filter_editor, nil)}
  end

  def handle_event(
        "save_filter",
        %{"filter" => %{"field" => field, "condition" => condition} = params},
        socket
      ) do
    filter = %{
      "field" => field,
      "condition" => condition,
      "value" => Map.get(params, "value", "")
    }

    index = socket.assigns.filter_editor && socket.assigns.filter_editor.index

    filters =
      if is_integer(index) do
        List.replace_at(socket.assigns.item_filters, index, filter)
      else
        socket.assigns.item_filters ++ [filter]
      end

    {:noreply,
     socket
     |> assign(:item_filters, filters)
     |> assign(:filter_editor, nil)
     |> assign_entries(socket.assigns.collection)}
  end

  def handle_event("delete_filter", %{"index" => index}, socket) do
    index = sort_index(index)

    filters =
      if is_integer(index),
        do: List.delete_at(socket.assigns.item_filters, index),
        else: socket.assigns.item_filters

    {:noreply,
     socket
     |> assign(:item_filters, filters)
     |> assign(:filter_editor, nil)
     |> assign_entries(socket.assigns.collection)}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:item_query, "")
     |> assign(:item_filters, [])
     |> assign(:filter_editor, nil)
     |> assign_entries(socket.assigns.collection)}
  end

  def handle_event("collection_menu_action", %{"label" => label}, socket) do
    {:noreply, put_flash(socket, :info, "#{label} is ready for implementation.")}
  end

  def handle_event("delete_entry", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    entry = Collections.get_entry!(tenant, id)
    ensure_entry_belongs_to_collection!(socket.assigns.collection, entry)
    {:ok, _entry} = Collections.delete_entry(tenant, entry)

    {:noreply, assign_entries(socket, socket.assigns.collection)}
  end

  def handle_event(
        "update_item_field",
        %{"item_id" => id, "field" => field_key, "value" => value},
        socket
      ) do
    tenant = socket.assigns.current_tenant
    entry = Collections.get_entry!(tenant, id)
    ensure_entry_belongs_to_collection!(socket.assigns.collection, entry)
    field = collection_field!(socket.assigns.fields, field_key)
    payload = update_payload_value(entry.payload, field, value)

    case Collections.update_entry(tenant, entry, %{"payload" => payload}) do
      {:ok, _entry} ->
        {:noreply, assign_entries(socket, socket.assigns.collection)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update #{field.label}.")}
    end
  end

  def handle_event("open_image_modal", %{"id" => id, "field" => field_key}, socket) do
    entry = Collections.get_entry!(socket.assigns.current_tenant, id)
    ensure_entry_belongs_to_collection!(socket.assigns.collection, entry)
    field = collection_field!(socket.assigns.fields, field_key)

    {:noreply,
     socket
     |> assign(:image_modal, %{entry_id: entry.id, field_key: field.field_key, label: field.label})
     |> cancel_uploads(:inline_image)}
  end

  def handle_event("open_image_url_modal", %{"id" => id, "field" => field_key}, socket) do
    entry = Collections.get_entry!(socket.assigns.current_tenant, id)
    ensure_entry_belongs_to_collection!(socket.assigns.collection, entry)
    field = collection_field!(socket.assigns.fields, field_key)

    {:noreply,
     assign(socket, :image_url_modal, %{
       entry_id: entry.id,
       field_key: field.field_key,
       label: field.label,
       url: image_url(raw_entry_field_value(entry, field)) || ""
     })}
  end

  def handle_event("close_image_modal", _params, socket) do
    {:noreply, assign(socket, :image_modal, nil) |> cancel_uploads(:inline_image)}
  end

  def handle_event("close_image_url_modal", _params, socket) do
    {:noreply, assign(socket, :image_url_modal, nil)}
  end

  def handle_event("remove_item_image", %{"id" => id, "field" => field_key}, socket) do
    tenant = socket.assigns.current_tenant
    entry = Collections.get_entry!(tenant, id)
    ensure_entry_belongs_to_collection!(socket.assigns.collection, entry)
    field = collection_field!(socket.assigns.fields, field_key)
    payload = Map.delete(entry.payload || %{}, field.field_key)

    case Collections.update_entry(tenant, entry, %{"payload" => payload}) do
      {:ok, _entry} ->
        {:noreply, assign_entries(socket, socket.assigns.collection)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not remove #{field.label}.")}
    end
  end

  def handle_event("save_item_image", _params, %{assigns: %{image_modal: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("save_item_image", _params, socket) do
    %{entry_id: id, field_key: field_key} = socket.assigns.image_modal
    tenant = socket.assigns.current_tenant
    entry = Collections.get_entry!(tenant, id)
    ensure_entry_belongs_to_collection!(socket.assigns.collection, entry)
    field = collection_field!(socket.assigns.fields, field_key)

    urls =
      consume_uploaded_entries(socket, :inline_image, fn meta, upload_entry ->
        {:ok,
         Uploads.store_live_upload!(upload_entry, meta, {:tenant, tenant},
           type: ["collections", socket.assigns.collection.id, field.field_key, "images"]
         )}
      end)

    case urls do
      [url | _rest] ->
        payload = put_image_payload_value(entry.payload, field, url)

        case Collections.update_entry(tenant, entry, %{"payload" => payload}) do
          {:ok, _entry} ->
            {:noreply,
             socket
             |> assign(:image_modal, nil)
             |> assign_entries(socket.assigns.collection)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not replace #{field.label}.")}
        end

      [] ->
        {:noreply, put_flash(socket, :error, "Choose an image before saving.")}
    end
  end

  def handle_event(
        "save_item_image_url",
        %{"url" => _url},
        %{assigns: %{image_url_modal: nil}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event("save_item_image_url", %{"url" => url}, socket) do
    %{entry_id: id, field_key: field_key} = socket.assigns.image_url_modal
    tenant = socket.assigns.current_tenant
    entry = Collections.get_entry!(tenant, id)
    ensure_entry_belongs_to_collection!(socket.assigns.collection, entry)
    field = collection_field!(socket.assigns.fields, field_key)
    payload = put_image_payload_value(entry.payload, field, String.trim(url))

    case Collections.update_entry(tenant, entry, %{"payload" => payload}) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> assign(:image_url_modal, nil)
         |> assign_entries(socket.assigns.collection)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not replace #{field.label}.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={@collection.name}
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
          patch={"#{@collection_base_path}/#{@collection.id}/items/new"}
          variant="primary"
        >
          <.icon name="hero-plus" class="size-4" /> Add Item
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new_field, :edit_field]}
        module={MangoCMSWeb.Tenant.Admin.CollectionLive.FieldFormComponent}
        id={@field.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        collection={@collection}
        field={@field}
        patch={"#{@collection_base_path}/#{@collection.id}"}
      />

      <.live_component
        :if={@live_action in [:new_entry, :edit_entry]}
        module={MangoCMSWeb.Tenant.Admin.CollectionItemLive.FormComponent}
        id={@entry.id || :new}
        title={@page_title}
        action={entry_action(@live_action)}
        tenant={@current_tenant}
        current_user={@current_user}
        collection={@collection}
        fields={@fields}
        entry={@entry}
        patch={"#{@collection_base_path}/#{@collection.id}"}
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
              <button
                id="refresh-items-button"
                type="button"
                phx-click="refresh_items"
                class="btn btn-sm btn-ghost group/refresh"
              >
                <.icon
                  name="hero-arrow-path"
                  class="size-4 group-[.phx-click-loading]/refresh:animate-spin"
                /> Refresh
              </button>
            </div>
            <div class="flex flex-1 flex-wrap items-center justify-end gap-2 min-w-0">
              <form phx-change="search_items" class="contents">
                <label class="input input-bordered input-sm flex min-w-64 items-center gap-2 rounded-full">
                  <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
                  <input
                    id="collection-item-search"
                    type="search"
                    name="q"
                    value={@item_query}
                    phx-debounce="300"
                    placeholder="Search"
                    class="grow"
                  />
                </label>
              </form>
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
                  Sort <span class="badge badge-sm">{length(@item_sorts)}</span>
                </button>
                <div
                  :if={@sorts_open?}
                  id="sort-popover"
                  class="absolute right-0 z-30 mt-3 w-96 rounded-lg border border-base-300 bg-base-100 shadow-xl"
                >
                  <div :if={is_nil(@sort_editor)}>
                    <div class="border-b border-base-300 p-5 text-sm text-base-content/70">
                      If no sorts are added, items appear in the order in which they were created.
                    </div>
                    <div id="active-sorts">
                      <div
                        :for={{sort, index} <- Enum.with_index(@item_sorts)}
                        class="grid grid-cols-[auto_1fr_auto] items-center gap-4 border-b border-base-300 p-4"
                      >
                        <span class="cursor-grab text-primary">::</span>
                        <div>
                          <p class="font-semibold">{sort_field_label(sort["field"], @fields)}</p>
                          <p class="text-sm text-base-content/60">
                            {sort_direction_label(sort["direction"])}
                          </p>
                        </div>
                        <div class="flex gap-2">
                          <button
                            type="button"
                            phx-click="open_sort_form"
                            phx-value-index={index}
                            class="btn btn-circle btn-outline btn-sm"
                          >
                            <.icon name="hero-pencil" class="size-4" />
                          </button>
                          <button
                            type="button"
                            phx-click="delete_sort"
                            phx-value-index={index}
                            class="btn btn-circle btn-outline btn-sm"
                          >
                            <.icon name="hero-trash" class="size-4" />
                          </button>
                        </div>
                      </div>
                      <div
                        :if={@item_sorts == []}
                        class="border-b border-base-300 p-4 text-sm text-base-content/60"
                      >
                        No sorts added.
                      </div>
                    </div>
                    <button
                      type="button"
                      phx-click="open_sort_form"
                      class="btn btn-ghost m-2 w-[calc(100%-1rem)] justify-start border border-primary/30 text-primary"
                    >
                      <.icon name="hero-plus" class="size-4" /> Add a Sort
                    </button>
                  </div>
                  <div :if={@sort_editor} class="p-5">
                    <button
                      type="button"
                      phx-click="close_sort_form"
                      class="btn btn-ghost btn-sm mb-6"
                    >
                      <.icon name="hero-arrow-left" class="size-4" /> All fields
                    </button>
                    <.form for={to_form(%{}, as: :sort)} id="sort-form" phx-submit="save_sort">
                      <label class="form-control">
                        <span class="label-text">Sort by</span>
                        <select name="sort[field]" class="select select-bordered">
                          <option
                            :for={{label, field} <- sort_field_options(@fields)}
                            value={field}
                            selected={@sort_editor.field == field}
                          >
                            {label}
                          </option>
                        </select>
                      </label>
                      <div class="mt-6">
                        <p class="mb-2 text-sm font-medium">Select the order</p>
                        <label class="flex cursor-pointer items-center gap-3 py-2">
                          <input
                            type="radio"
                            name="sort[direction]"
                            value="asc"
                            checked={@sort_editor.direction == "asc"}
                            class="radio radio-primary"
                          />
                          <span>A -> Z</span>
                        </label>
                        <label class="flex cursor-pointer items-center gap-3 py-2">
                          <input
                            type="radio"
                            name="sort[direction]"
                            value="desc"
                            checked={@sort_editor.direction == "desc"}
                            class="radio radio-primary"
                          />
                          <span>Z -> A</span>
                        </label>
                      </div>
                      <div class="mt-8 rounded-lg border border-primary/30 bg-primary/10 p-4 text-sm">
                        Sorts and filters do not apply to content on your site yet.
                      </div>
                      <div class="mt-8 flex justify-end gap-3">
                        <button type="button" phx-click="close_sort_form" class="btn btn-outline">
                          Cancel
                        </button>
                        <button type="submit" class="btn btn-primary">Update</button>
                      </div>
                    </.form>
                  </div>
                </div>
              </div>
              <div class="relative">
                <button
                  id="filter-items-button"
                  type="button"
                  phx-click="toggle_filters"
                  class="btn btn-sm btn-outline rounded-full"
                >
                  Filter
                  <span :if={@item_filters != []} class="badge badge-sm">
                    {length(@item_filters)}
                  </span>
                </button>
                <div
                  :if={@filters_open?}
                  id="filter-popover"
                  class="absolute right-0 z-1000 mt-3 w-96 rounded-lg border border-base-300 bg-base-100 shadow-xl"
                >
                  <div :if={is_nil(@filter_editor)}>
                    <div id="active-filters">
                      <div
                        :for={{filter, index} <- Enum.with_index(@item_filters)}
                        class="grid grid-cols-[1fr_auto] items-center gap-4 border-b border-base-300 p-4"
                      >
                        <div>
                          <p class="font-semibold">{filter_field_label(filter["field"], @fields)}</p>
                          <p class="text-sm text-base-content/60">{filter_summary(filter)}</p>
                        </div>
                        <div class="flex gap-2">
                          <button
                            type="button"
                            phx-click="open_filter_form"
                            phx-value-index={index}
                            class="btn btn-circle btn-outline btn-sm"
                          >
                            <.icon name="hero-pencil" class="size-4" />
                          </button>
                          <button
                            type="button"
                            phx-click="delete_filter"
                            phx-value-index={index}
                            class="btn btn-circle btn-outline btn-sm"
                          >
                            <.icon name="hero-trash" class="size-4" />
                          </button>
                        </div>
                      </div>
                      <div
                        :if={@item_filters == []}
                        class="border-b border-base-300 p-4 text-sm text-base-content/60"
                      >
                        No filters added.
                      </div>
                    </div>
                    <button
                      type="button"
                      phx-click="open_filter_form"
                      class="btn btn-ghost m-2 w-[calc(100%-1rem)] justify-start border border-primary/30 text-primary"
                    >
                      <.icon name="hero-plus" class="size-4" /> New Filter
                    </button>
                  </div>
                  <div :if={@filter_editor} class="p-5">
                    <button
                      type="button"
                      phx-click="close_filter_form"
                      class="btn btn-ghost btn-sm mb-6"
                    >
                      <.icon name="hero-arrow-left" class="size-4" /> All fields
                    </button>
                    <.form for={to_form(%{}, as: :filter)} id="filter-form" phx-submit="save_filter">
                      <label class="form-control">
                        <span class="label-text">Select field</span>
                        <select name="filter[field]" class="select select-bordered">
                          <option
                            :for={{label, field} <- filter_field_options(@fields)}
                            value={field}
                            selected={@filter_editor.field == field}
                          >
                            {label}
                          </option>
                        </select>
                      </label>
                      <label class="form-control mt-5">
                        <span class="label-text">Choose a condition</span>
                        <select name="filter[condition]" class="select select-bordered">
                          <option
                            :for={{label, condition} <- filter_condition_options()}
                            value={condition}
                            selected={@filter_editor.condition == condition}
                          >
                            {label}
                          </option>
                        </select>
                      </label>
                      <label class="form-control mt-5">
                        <span class="label-text">Enter a value</span>
                        <input
                          name="filter[value]"
                          type="text"
                          value={@filter_editor.value}
                          class="input input-bordered"
                        />
                      </label>
                      <div class="mt-8 rounded-lg border border-primary/30 bg-primary/10 p-4 text-sm">
                        <strong>Note:</strong>
                        Collection filters will not apply to the item order on site pages.
                      </div>
                      <div class="mt-8 flex justify-end gap-3">
                        <button type="button" phx-click="close_filter_form" class="btn btn-outline">
                          Cancel
                        </button>
                        <button type="submit" class="btn btn-primary">
                          {if(is_integer(@filter_editor.index), do: "Update", else: "Add Filter")}
                        </button>
                      </div>
                    </.form>
                  </div>
                </div>
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
                    <button
                      type="button"
                      phx-click="collection_menu_action"
                      phx-value-label="Import items"
                    >
                      <.icon name="hero-arrow-down-tray" class="size-4" /> Import items
                    </button>
                  </li>
                  <li>
                    <button
                      type="button"
                      phx-click="collection_menu_action"
                      phx-value-label="Export to CSV"
                    >
                      <.icon name="hero-arrow-up-tray" class="size-4" /> Export to CSV
                    </button>
                  </li>
                  <li>
                    <button
                      type="button"
                      phx-click="collection_menu_action"
                      phx-value-label="Collection settings"
                    >
                      <.icon name="hero-cog-6-tooth" class="size-4" /> Collection settings
                    </button>
                  </li>
                  <li>
                    <button
                      type="button"
                      phx-click="collection_menu_action"
                      phx-value-label="Permissions & privacy"
                    >
                      <.icon name="hero-key" class="size-4" /> Permissions & privacy
                    </button>
                  </li>
                  <li>
                    <button
                      type="button"
                      phx-click="collection_menu_action"
                      phx-value-label="Submit feedback"
                    >
                      <.icon name="hero-chat-bubble-left" class="size-4" /> Submit feedback
                    </button>
                  </li>
                </ul>
              </div>
              <div class="join">
                <button class="btn join-item btn-sm btn-active">Live</button>
                <button class="btn join-item btn-sm">Sandbox</button>
              </div>
            </div>
          </div>

          <div :if={@collection_layout == "table"} class="overflow-x-auto">
            <table id="collection-ledger-table" class="table border-collapse">
              <thead class="bg-primary/10">
                <tr>
                  <th class="border border-primary/20">
                    <input type="checkbox" class="checkbox checkbox-sm" />
                  </th>
                  <th :for={field <- visible_fields(@fields)} class="border border-primary/20">
                    {field.label}
                  </th>
                  <th class="border border-primary/20">Slug</th>
                  <th class="border border-primary/20">Status</th>
                  <th class="border border-primary/20"></th>
                </tr>
              </thead>
              <tbody>
                <tr :for={entry <- @entries}>
                  <td class="border border-primary/20">
                    <input type="checkbox" class="checkbox checkbox-sm" />
                  </td>
                  <td :for={field <- visible_fields(@fields)} class="border border-primary/20 p-0">
                    <.inline_field_cell entry={entry} field={field} />
                  </td>
                  <td class="border border-primary/20">{entry.slug}</td>
                  <td class="border border-primary/20">
                    <span class={status_class(entry.status)}>{human_status(entry.status)}</span>
                  </td>
                  <td class="border border-primary/20">
                    <.link
                      id={"edit-collection-item-#{entry.id}"}
                      patch={"#{@collection_base_path}/#{@collection.id}/items/#{entry.id}/edit"}
                      class="btn btn-xs btn-ghost"
                    >
                      Edit
                    </.link>
                    <button
                      id={"delete-collection-item-#{entry.id}"}
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
                      patch={"#{@collection_base_path}/#{@collection.id}/items/new"}
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
              patch={"#{@collection_base_path}/#{@collection.id}/items/new"}
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

          <div id="collection-fields" class="min-h-0 flex-1 overflow-y-auto">
            <div
              :for={field <- @fields}
              id={"collection-field-#{field.id}"}
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
                      id={"edit-collection-field-#{field.id}"}
                      patch={"#{@collection_base_path}/#{@collection.id}/fields/#{field.id}/edit"}
                    >
                      Edit
                    </.link>
                  </li>
                  <li>
                    <button disabled={
                      field.primary or
                        not CollectionField.primary_field_type?(field.field_type)
                    }>
                      Make primary
                    </button>
                  </li>
                  <li><button disabled={field.system}>Duplicate field</button></li>
                  <li><button disabled={field.system}>Duplicate with content</button></li>
                  <li>
                    <button
                      id={"delete-collection-field-#{field.id}"}
                      type="button"
                      phx-click="delete_field"
                      phx-value-id={field.id}
                      disabled={field.system}
                      data-confirm="Delete this field and rebuild item indexes?"
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
              id="new-collection-field-button"
              patch={"#{@collection_base_path}/#{@collection.id}/fields/new"}
              class="btn btn-primary w-full"
            >
              <.icon name="hero-plus" class="size-4" /> Add New Field
            </.button>
          </div>
        </aside>

        <dialog :if={@image_modal} id="collection-image-modal" open class="modal modal-open">
          <div class="modal-box">
            <h3 class="font-semibold">Replace {@image_modal.label}</h3>
            <p class="mt-1 text-sm text-base-content/60">
              Upload a new image for this collection item.
            </p>
            <div class="mt-4 rounded-lg border border-dashed border-base-300 bg-base-200 p-4">
              <.live_file_input
                upload={@uploads.inline_image}
                class="file-input file-input-bordered w-full"
              />
              <div class="mt-3 grid gap-2">
                <p :for={entry <- @uploads.inline_image.entries} class="text-sm text-base-content/70">
                  {entry.client_name} · {entry.progress}%
                </p>
              </div>
            </div>
            <div class="modal-action">
              <button type="button" phx-click="close_image_modal" class="btn btn-ghost">
                Cancel
              </button>
              <button type="button" phx-click="save_item_image" class="btn btn-primary">
                Save image
              </button>
            </div>
          </div>
          <form method="dialog" class="modal-backdrop">
            <button type="button" phx-click="close_image_modal">close</button>
          </form>
        </dialog>

        <dialog :if={@image_url_modal} id="collection-image-url-modal" open class="modal modal-open">
          <div class="modal-box">
            <h3 class="font-semibold">Replace {@image_url_modal.label} with URL</h3>
            <p class="mt-1 text-sm text-base-content/60">
              Paste an image URL for this collection item.
            </p>
            <form id="collection-image-url-form" phx-submit="save_item_image_url" class="mt-4">
              <label class="form-control">
                <span class="label-text">Image URL</span>
                <input
                  id="collection-image-url-input"
                  type="url"
                  name="url"
                  value={@image_url_modal.url}
                  placeholder="https://example.com/image.jpg"
                  class="input input-bordered"
                />
              </label>
              <div class="modal-action">
                <button type="button" phx-click="close_image_url_modal" class="btn btn-ghost">
                  Cancel
                </button>
                <button type="submit" class="btn btn-primary">Save URL</button>
              </div>
            </form>
          </div>
          <form method="dialog" class="modal-backdrop">
            <button type="button" phx-click="close_image_url_modal">close</button>
          </form>
        </dialog>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp stream_fields(socket, collection) do
    fields = Collections.list_collection_fields(socket.assigns.current_tenant, collection)

    socket
    |> assign(:fields, fields)
    |> stream(:fields, fields, reset: true)
  end

  defp assign_entries(socket, collection) do
    entries =
      Collections.list_entries(socket.assigns.current_tenant, collection, status: "all")
      |> filter_entries(socket.assigns.item_query, socket.assigns.item_filters)
      |> sort_entries(socket.assigns.item_sorts)

    assign(socket, :entries, entries)
  end

  defp next_field_position(socket) do
    socket.assigns.current_tenant
    |> Collections.list_collection_fields(socket.assigns.collection)
    |> Enum.map(& &1.position)
    |> case do
      [] -> 0
      positions -> Enum.max(positions) + 10
    end
  end

  defp ensure_field_belongs_to_collection!(collection, field) do
    if field.collection_id != collection.id do
      raise Ecto.NoResultsError, queryable: CollectionField
    end
  end

  defp ensure_entry_belongs_to_collection!(collection, entry) do
    if entry.collection_id != collection.id do
      raise Ecto.NoResultsError, queryable: CollectionItem
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

  defp sort_field_options(fields) do
    system_options = [
      {"Created At", "inserted_at"},
      {"Title", "title"},
      {"Slug", "slug"},
      {"Status", "status"}
    ]

    field_options =
      fields
      |> Enum.filter(& &1.visible)
      |> Enum.map(&{&1.label, &1.field_key})

    system_options ++ field_options
  end

  defp filter_field_options(fields), do: sort_field_options(fields)

  defp filter_field_label(field, fields) do
    filter_field_options(fields)
    |> Enum.find_value(human_status(field), fn {label, option_field} ->
      if option_field == field, do: label
    end)
  end

  defp filter_condition_options do
    [
      {"Is", "is"},
      {"Is not", "is_not"},
      {"Contains", "contains"},
      {"Does not contain", "not_contains"},
      {"Cell is empty", "empty"},
      {"Cell is not empty", "not_empty"}
    ]
  end

  defp filter_condition_label(condition) do
    filter_condition_options()
    |> Enum.find_value(human_status(condition), fn {label, option_condition} ->
      if option_condition == condition, do: label
    end)
  end

  defp filter_summary(%{"condition" => condition, "value" => value}) do
    case condition do
      "empty" -> "Cell is empty"
      "not_empty" -> "Cell is not empty"
      _other -> "#{filter_condition_label(condition)} #{value}"
    end
  end

  defp sort_field_label(field, fields) do
    sort_field_options(fields)
    |> Enum.find_value(human_status(field), fn {label, option_field} ->
      if option_field == field, do: label
    end)
  end

  defp sort_direction_label("desc"), do: "Z -> A"
  defp sort_direction_label(_direction), do: "A -> Z"

  defp sort_index(value) when is_binary(value) do
    case Integer.parse(value) do
      {index, ""} when index >= 0 -> index
      _other -> nil
    end
  end

  defp sort_index(_value), do: nil

  attr :entry, :any, required: true
  attr :field, :any, required: true

  defp inline_field_cell(assigns) do
    assigns =
      assigns
      |> assign(:value, raw_entry_field_value(assigns.entry, assigns.field))
      |> assign(:display_value, entry_field_value(assigns.entry, assigns.field))
      |> assign(:cell_id, "collection-item-#{assigns.entry.id}-#{assigns.field.field_key}")

    ~H"""
    <div class="min-w-40">
      <div
        :if={@field.field_type in ~w(image gallery)}
        class="group/cell flex min-h-16 items-center gap-2 border-2 border-transparent px-2 py-1 transition focus-within:border-primary hover:bg-primary/5"
        tabindex="0"
      >
        <div class="avatar">
          <div class="h-12 w-24 rounded border border-base-300 bg-base-200">
            <img
              :if={image_url(@value)}
              src={image_url(@value)}
              alt=""
              class="h-full w-full object-cover"
            />
            <div :if={!image_url(@value)} class="grid h-full w-full place-items-center">
              <.icon name="hero-photo" class="size-5 text-base-content/40" />
            </div>
          </div>
        </div>
        <div class="dropdown dropdown-end ml-auto">
          <button
            type="button"
            tabindex="0"
            class="btn btn-primary btn-sm h-10 min-h-10 px-3 opacity-0 transition group-hover/cell:opacity-100 group-focus-within/cell:opacity-100 focus:opacity-100"
          >
            <.icon name="hero-ellipsis-horizontal" class="size-4" />
          </button>
          <ul
            tabindex="0"
            class="menu dropdown-content z-20 mt-2 w-72 rounded-lg border border-base-300 bg-base-100 p-3 text-base shadow-xl"
          >
            <li>
              <button
                id={"replace-image-#{@cell_id}"}
                type="button"
                phx-click="open_image_modal"
                phx-value-id={@entry.id}
                phx-value-field={@field.field_key}
              >
                <.icon name="hero-arrow-path" class="size-5" /> Replace image
              </button>
            </li>
            <li>
              <button
                type="button"
                phx-click="open_image_url_modal"
                phx-value-id={@entry.id}
                phx-value-field={@field.field_key}
              >
                <.icon name="hero-link" class="size-5" /> Replace with URL
              </button>
            </li>
            <li class="border-t border-base-300 my-2"></li>
            <li>
              <a :if={image_url(@value)} href={image_url(@value)} target="_blank">
                <.icon name="hero-arrows-pointing-out" class="size-5" /> Preview
              </a>
              <button :if={!image_url(@value)} type="button" disabled>
                <.icon name="hero-arrows-pointing-out" class="size-5" /> Preview
              </button>
            </li>
            <li>
              <a :if={image_url(@value)} href={image_url(@value)} download>
                <.icon name="hero-arrow-down-tray" class="size-5" /> Download image
              </a>
              <button :if={!image_url(@value)} type="button" disabled>
                <.icon name="hero-arrow-down-tray" class="size-5" /> Download image
              </button>
            </li>
            <li class="border-t border-base-300 my-2"></li>
            <li>
              <button
                id={"remove-image-#{@cell_id}"}
                type="button"
                phx-click="remove_item_image"
                phx-value-id={@entry.id}
                phx-value-field={@field.field_key}
                class="text-error"
              >
                <.icon name="hero-trash" class="size-5" /> Delete image
              </button>
            </li>
          </ul>
        </div>
      </div>

      <form
        :if={@field.field_type not in ~w(image gallery boolean select)}
        id={"inline-field-form-#{@cell_id}"}
        phx-change="update_item_field"
        class="group/cell block min-h-10 border-2 border-transparent transition focus-within:border-primary hover:bg-primary/5"
      >
        <input type="hidden" name="item_id" value={@entry.id} />
        <input type="hidden" name="field" value={@field.field_key} />
        <input
          id={"inline-field-input-#{@cell_id}"}
          name="value"
          type={inline_input_type(@field)}
          value={inline_input_value(@value, @field)}
          phx-debounce="500"
          class="h-10 w-full min-w-40 bg-transparent px-2 text-sm outline-none"
        />
      </form>

      <form
        :if={@field.field_type == "select"}
        id={"inline-field-form-#{@cell_id}"}
        phx-change="update_item_field"
        class="group/cell block min-h-10 border-2 border-transparent transition focus-within:border-primary hover:bg-primary/5"
      >
        <input type="hidden" name="item_id" value={@entry.id} />
        <input type="hidden" name="field" value={@field.field_key} />
        <select
          id={"inline-field-input-#{@cell_id}"}
          name="value"
          class="h-10 w-full min-w-40 bg-transparent px-2 text-sm outline-none"
        >
          <option value="">Choose</option>
          <option
            :for={option <- select_options(@field)}
            value={option}
            selected={to_string(@value || "") == option}
          >
            {option}
          </option>
        </select>
      </form>

      <label
        :if={@field.field_type == "boolean"}
        class="group/cell flex min-h-10 items-center gap-2 border-2 border-transparent px-2 transition focus-within:border-primary hover:bg-primary/5"
      >
        <input
          id={"inline-field-input-#{@cell_id}"}
          type="checkbox"
          checked={@value in [true, "true", "1", 1]}
          class="toggle toggle-xs"
          phx-click="update_item_field"
          phx-value-item_id={@entry.id}
          phx-value-field={@field.field_key}
          phx-value-value={if(@value in [true, "true", "1", 1], do: "false", else: "true")}
        />
        <span class="text-xs text-base-content/60">{@display_value}</span>
      </label>
    </div>
    """
  end

  defp entry_field_value(%CollectionItem{payload: payload}, %CollectionField{} = field) do
    %CollectionItem{payload: payload}
    |> raw_entry_field_value(field)
    |> format_value()
  end

  defp raw_entry_field_value(%CollectionItem{payload: payload}, %CollectionField{} = field) do
    payload = if is_map(payload), do: payload, else: %{}
    Map.get(payload, field.field_key)
  end

  defp entry_title(%CollectionItem{title: title}, _fields) when is_binary(title) and title != "",
    do: title

  defp entry_title(%CollectionItem{} = entry, fields) do
    case Enum.find(fields, & &1.primary) do
      nil -> entry.slug
      field -> entry_field_value(entry, field)
    end
  end

  defp entry_image(%CollectionItem{payload: payload}, fields) do
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

  defp inline_input_type(%CollectionField{field_type: "number"}), do: "number"
  defp inline_input_type(%CollectionField{field_type: "datetime"}), do: "datetime-local"
  defp inline_input_type(%CollectionField{field_type: "date"}), do: "date"
  defp inline_input_type(%CollectionField{field_type: "url"}), do: "url"
  defp inline_input_type(%CollectionField{field_type: "email"}), do: "email"
  defp inline_input_type(_field), do: "text"

  defp inline_input_value(value, %CollectionField{field_type: "datetime"})
       when is_binary(value),
       do: String.slice(value, 0, 16)

  defp inline_input_value(value, _field) when value in [nil, ""], do: ""
  defp inline_input_value(value, _field), do: to_string(value)

  defp select_options(%CollectionField{settings: settings}) when is_map(settings) do
    case Map.get(settings, "options", []) do
      options when is_list(options) -> Enum.map(options, &to_string/1)
      _other -> []
    end
  end

  defp select_options(_field), do: []

  defp image_url([url | _rest]) when is_binary(url), do: url
  defp image_url(url) when is_binary(url) and url != "", do: url
  defp image_url(_value), do: nil

  defp collection_field!(fields, field_key) do
    Enum.find(fields, &(&1.field_key == field_key)) ||
      raise Ecto.NoResultsError, queryable: CollectionField
  end

  defp filter_entries(entries, query, filters) do
    entries
    |> filter_entries_by_rules(filters)
    |> filter_entries_by_query(query)
  end

  defp filter_entries_by_rules(entries, filters) when is_list(filters) do
    Enum.filter(entries, fn entry ->
      Enum.all?(filters, &entry_matches_filter?(entry, &1))
    end)
  end

  defp filter_entries_by_rules(entries, _filters), do: entries

  defp filter_entries_by_query(entries, query) when query in [nil, ""], do: entries

  defp filter_entries_by_query(entries, query) do
    query = String.downcase(String.trim(query))

    Enum.filter(entries, fn entry ->
      entry
      |> searchable_entry_text()
      |> String.contains?(query)
    end)
  end

  defp searchable_entry_text(%CollectionItem{} = entry) do
    payload =
      entry.payload
      |> case do
        payload when is_map(payload) -> payload
        _other -> %{}
      end
      |> Map.values()
      |> Enum.map_join(" ", &format_value/1)

    [entry.title, entry.slug, entry.status, payload]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> String.downcase()
  end

  defp entry_matches_filter?(%CollectionItem{} = entry, %{
         "field" => field,
         "condition" => condition,
         "value" => value
       }) do
    entry
    |> filter_value(field)
    |> compare_filter_value(condition, value)
  end

  defp entry_matches_filter?(_entry, _filter), do: true

  defp filter_value(%CollectionItem{} = entry, "slug"), do: entry.slug
  defp filter_value(%CollectionItem{} = entry, "status"), do: entry.status
  defp filter_value(%CollectionItem{} = entry, "title"), do: entry.title
  defp filter_value(%CollectionItem{} = entry, "inserted_at"), do: entry.inserted_at

  defp filter_value(%CollectionItem{payload: payload}, field) do
    payload = if is_map(payload), do: payload, else: %{}
    Map.get(payload, field)
  end

  defp compare_filter_value(value, "empty", _expected), do: blank_filter_value?(value)
  defp compare_filter_value(value, "not_empty", _expected), do: not blank_filter_value?(value)

  defp compare_filter_value(value, "is", expected) do
    normalize_filter_value(value) == normalize_filter_value(expected)
  end

  defp compare_filter_value(value, "is_not", expected) do
    normalize_filter_value(value) != normalize_filter_value(expected)
  end

  defp compare_filter_value(value, "contains", expected) do
    String.contains?(normalize_filter_value(value), normalize_filter_value(expected))
  end

  defp compare_filter_value(value, "not_contains", expected) do
    not String.contains?(normalize_filter_value(value), normalize_filter_value(expected))
  end

  defp compare_filter_value(_value, _condition, _expected), do: true

  defp normalize_filter_value(value) when value in [nil, ""], do: ""

  defp normalize_filter_value(value) when is_binary(value),
    do: value |> String.trim() |> String.downcase()

  defp normalize_filter_value(value),
    do: value |> format_value() |> String.trim() |> String.downcase()

  defp blank_filter_value?(value), do: value in [nil, "", []]

  defp sort_entries(entries, sorts) when is_list(sorts) do
    sorts
    |> Enum.reverse()
    |> Enum.reduce(entries, fn %{"field" => field, "direction" => direction}, entries ->
      Enum.sort_by(entries, &sort_value(&1, field), sort_direction(direction))
    end)
  end

  defp sort_entries(entries, _sorts), do: entries

  defp sort_value(%CollectionItem{} = entry, "slug"), do: entry.slug || ""
  defp sort_value(%CollectionItem{} = entry, "status"), do: entry.status || ""
  defp sort_value(%CollectionItem{} = entry, "title"), do: entry.title || ""

  defp sort_value(%CollectionItem{} = entry, "inserted_at"),
    do: entry.inserted_at || ~U[1970-01-01 00:00:00Z]

  defp sort_value(%CollectionItem{payload: payload}, field) do
    payload = if is_map(payload), do: payload, else: %{}
    payload |> Map.get(field, "") |> sortable_payload_value()
  end

  defp sortable_payload_value(value) when is_binary(value), do: String.downcase(value)
  defp sortable_payload_value(value) when is_number(value), do: value
  defp sortable_payload_value(value) when is_boolean(value), do: if(value, do: 1, else: 0)
  defp sortable_payload_value(value) when value in [nil, ""], do: ""
  defp sortable_payload_value(value), do: to_string(value)

  defp sort_direction("asc"), do: :asc
  defp sort_direction(_direction), do: :desc

  defp update_payload_value(payload, %CollectionField{} = field, value) do
    payload = if is_map(payload), do: payload, else: %{}

    value =
      case field.field_type do
        "number" -> parse_inline_number(value)
        "boolean" -> value in [true, "true", "1", 1]
        _type -> value
      end

    if value in [nil, ""] do
      Map.delete(payload, field.field_key)
    else
      Map.put(payload, field.field_key, value)
    end
  end

  defp put_image_payload_value(payload, %CollectionField{} = field, value) do
    payload = if is_map(payload), do: payload, else: %{}

    cond do
      value in [nil, ""] ->
        Map.delete(payload, field.field_key)

      field.field_type == "gallery" ->
        Map.put(payload, field.field_key, [value])

      true ->
        Map.put(payload, field.field_key, value)
    end
  end

  defp parse_inline_number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _other -> value
    end
  end

  defp parse_inline_number(value), do: value

  defp cancel_uploads(socket, upload_name) do
    Enum.reduce(socket.assigns.uploads[upload_name].entries, socket, fn entry, socket ->
      cancel_upload(socket, upload_name, entry.ref)
    end)
  end

  defp status_class("published"), do: "badge badge-success"
  defp status_class("archived"), do: "badge badge-ghost"
  defp status_class(_status), do: "badge badge-warning"

  defp collection_base_path(url) when is_binary(url) do
    if String.contains?(url, "/admin/collections"),
      do: "/admin/collections",
      else: "/admin/collections"
  end
end
