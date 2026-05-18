defmodule MangoCMSWeb.Tenant.Admin.SectionLive.Builder do
  use MangoCMSWeb, :live_view

  alias MangoCMS.ContentTree
  alias MangoCMS.Tenant.Collections
  alias MangoCMS.Tenant.Collections.CollectionItem
  alias MangoCMS.Tenant.Pages
  alias MangoCMSWeb.AdminGuard
  alias MangoCMSWeb.Live.Admin.EditorCanvas

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_pages) do
      {:ok, socket} -> {:ok, socket}
      {:redirect, socket} -> {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    tenant = socket.assigns.current_tenant
    section = Pages.get_section!(tenant, id)
    tree = ContentTree.normalize_paths(section.content_tree || [])
    source_config = section.source_config || %{}
    collection_fields = collection_fields(tenant, source_config)

    {:noreply,
     socket
     |> assign(:section, section)
     |> assign(:tree, tree)
     |> assign(:selected_id, nil)
     |> assign(:left_tab, "components")
     |> assign(:config_tab, "source")
     |> assign(:right_sidebar_open?, true)
     |> assign(:right_sidebar_size, "normal")
     |> assign(:collections, Collections.list_collections(tenant))
     |> assign(:collection_fields, collection_fields)
     |> assign(:settings, section.settings || %{})
     |> assign(:source_config, source_config)
     |> assign(:filters, section.filters || %{})
     |> assign(:loop_settings, section.loop_settings || %{"enabled" => false, "limit" => 6})
     |> assign_preview_tree()}
  end

  @impl true
  def handle_event("select_element", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:selected_id, id)
     |> assign(:right_sidebar_open?, true)
     |> assign(:right_sidebar_size, normalize_sidebar_size(socket.assigns[:right_sidebar_size]))}
  end

  def handle_event("set_left_tab", %{"tab" => tab}, socket) when tab in ~w(components layers) do
    {:noreply, assign(socket, :left_tab, tab)}
  end

  def handle_event("set_config_tab", %{"tab" => tab}, socket)
      when tab in ~w(source filters loop settings) do
    {:noreply, assign(socket, :config_tab, tab)}
  end

  def handle_event("close_right_sidebar", _params, socket) do
    {:noreply, assign(socket, :right_sidebar_open?, false)}
  end

  def handle_event("set_right_sidebar_size", %{"size" => size}, socket)
      when size in ~w(minimized normal maximized) do
    {:noreply,
     socket
     |> assign(:right_sidebar_open?, true)
     |> assign(:right_sidebar_size, size)}
  end

  def handle_event("add_node", %{"name" => name}, socket) do
    tree = ContentTree.insert_node(socket.assigns.tree, "root", new_node(name), :into)
    {:noreply, socket |> assign(:tree, tree) |> assign_preview_tree()}
  end

  def handle_event("delete_node", %{"id" => id}, socket) do
    socket =
      socket
      |> assign(:tree, ContentTree.delete_node(socket.assigns.tree, id))
      |> maybe_clear_selection(id)
      |> assign_preview_tree()

    {:noreply, socket}
  end

  def handle_event("copy_node", _params, socket), do: {:noreply, socket}

  def handle_event("delete_selected", _params, %{assigns: %{selected_id: id}} = socket)
      when is_binary(id) do
    {:noreply,
     socket
     |> assign(:tree, ContentTree.delete_node(socket.assigns.tree, id))
     |> assign(:selected_id, nil)
     |> assign_preview_tree()}
  end

  def handle_event("delete_selected", _params, socket), do: {:noreply, socket}

  def handle_event(
        "update_selected",
        %{"node" => _params},
        %{assigns: %{selected_id: nil}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "update_text_property",
        %{"id" => id, "property" => property, "value" => value},
        socket
      ) do
    tree = ContentTree.update_node_props(socket.assigns.tree, id, %{property => value || ""})

    {:noreply,
     socket
     |> assign(:tree, tree)
     |> assign(:selected_id, id)
     |> assign(:right_sidebar_open?, true)
     |> assign_preview_tree()}
  end

  def handle_event("update_selected", %{"node" => params}, socket) do
    selected_id = socket.assigns.selected_id

    prop_updates =
      params
      |> Map.take(["text", "href", "src", "alt", "target", "title", "level"])
      |> Map.reject(fn {_key, value} -> is_nil(value) end)

    tree = ContentTree.update_node_props(socket.assigns.tree, selected_id, prop_updates)

    tree =
      if Map.has_key?(params, "classes") do
        ContentTree.update_node_classes(tree, selected_id, %{"custom" => params["classes"] || ""})
      else
        tree
      end

    socket =
      socket
      |> assign(:tree, tree)
      |> assign_preview_tree()
      |> maybe_push_text_update(selected_id, prop_updates)

    {:noreply, socket}
  end

  def handle_event(
        "bind_selected_prop",
        %{"prop" => _prop, "path" => _path},
        %{assigns: %{selected_id: nil}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event("bind_selected_prop", %{"prop" => prop, "path" => path}, socket) do
    selected_id = socket.assigns.selected_id
    value = "{{#{path}}}"

    tree =
      ContentTree.update_node_props(socket.assigns.tree, selected_id, %{
        prop => value
      })

    socket =
      socket
      |> assign(:tree, tree)
      |> assign_preview_tree()
      |> maybe_push_text_update(selected_id, %{prop => preview_prop_value(socket, value)})

    {:noreply, socket}
  end

  def handle_event("bind_selected_prop", _params, socket), do: {:noreply, socket}

  def handle_event("update_section_config", %{"section_config" => params}, socket) do
    source_config =
      if Map.has_key?(params, "source") do
        update_source_config(socket.assigns.source_config, Map.get(params, "source", %{}))
      else
        socket.assigns.source_config
      end

    filters =
      if Map.has_key?(params, "filters") do
        update_filters(Map.get(params, "filters", %{}))
      else
        socket.assigns.filters
      end

    loop_settings =
      if Map.has_key?(params, "loop") do
        update_loop_settings(socket.assigns.loop_settings, Map.get(params, "loop", %{}))
      else
        socket.assigns.loop_settings
      end

    settings =
      if Map.has_key?(params, "settings") do
        update_settings(socket.assigns.settings, Map.get(params, "settings", %{}))
      else
        socket.assigns.settings
      end

    {:noreply,
     socket
     |> assign(:source_config, source_config)
     |> assign(:filters, filters)
     |> assign(:loop_settings, loop_settings)
     |> assign(:settings, settings)
     |> assign(
       :collection_fields,
       collection_fields(socket.assigns.current_tenant, source_config)
     )
     |> assign_preview_tree()
     |> push_preview_text_updates()}
  end

  def handle_event("save_section", _params, socket) do
    attrs = %{
      "settings" => socket.assigns.settings,
      "source_config" => socket.assigns.source_config,
      "filters" => socket.assigns.filters,
      "loop_settings" => socket.assigns.loop_settings,
      "content_tree" => socket.assigns.tree
    }

    case Pages.update_section(
           socket.assigns.current_tenant,
           socket.assigns.section,
           attrs,
           socket.assigns.current_user
         ) do
      {:ok, section} ->
        {:noreply,
         socket
         |> put_flash(:info, "Section builder saved")
         |> assign(:section, section)}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, error_text(changeset))}
    end
  end

  def handle_event("publish_section", _params, socket) do
    case Pages.publish_section(
           socket.assigns.current_tenant,
           socket.assigns.section,
           socket.assigns.current_user
         ) do
      {:ok, section} ->
        {:noreply,
         socket
         |> put_flash(:info, "Section published. Linked page embeds now use this version.")
         |> assign(:section, section)}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, error_text(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={"#{@section.name} builder"}
      subtitle="Build the reusable section content tree. Use field placeholders for dynamic data."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:sections}
    >
      <:actions>
        <.button id="back-to-sections-button" navigate={~p"/admin/sections"} class="btn btn-ghost">
          Back
        </.button>
        <button
          id="section-builder-publish-button"
          type="button"
          phx-click="publish_section"
          class="btn btn-primary"
        >
          Publish section
        </button>
      </:actions>

      <section id="section-builder" class={section_builder_grid_class(assigns)}>
        <aside class="flex min-h-0 flex-col overflow-hidden rounded-lg border border-base-300 bg-base-100">
          <div class="border-b border-base-300 p-3">
            <div class="join w-full">
              <button
                id="section-builder-tab-components"
                type="button"
                phx-click="set_left_tab"
                phx-value-tab="components"
                class={["btn join-item btn-sm flex-1", @left_tab == "components" && "btn-active"]}
              >
                Components
              </button>
              <button
                id="section-builder-tab-layers"
                type="button"
                phx-click="set_left_tab"
                phx-value-tab="layers"
                class={["btn join-item btn-sm flex-1", @left_tab == "layers" && "btn-active"]}
              >
                Layers
              </button>
            </div>
          </div>

          <div :if={@left_tab == "components"} class="min-h-0 flex-1 overflow-y-auto p-4">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Blocks</h2>
            <div class="mt-4 grid gap-2">
              <button
                :for={item <- block_palette()}
                id={"section-builder-add-#{item.name}"}
                type="button"
                phx-click="add_node"
                phx-value-name={item.name}
                class="btn btn-ghost justify-start"
              >
                <.icon name={item.icon} class="size-4" /> {item.label}
              </button>
            </div>
          </div>

          <div :if={@left_tab == "layers"} class="min-h-0 flex-1 overflow-y-auto p-4">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Layers</h2>
            <.layers_tree tree={@tree} selected_id={@selected_id} />
          </div>
        </aside>

        <main class="overflow-auto rounded-lg border border-base-300 bg-base-200 p-4">
          <.section_config_panel
            config_tab={@config_tab}
            collections={@collections}
            collection_fields={@collection_fields}
            settings={@settings}
            source_config={@source_config}
            filters={@filters}
            loop_settings={@loop_settings}
          />

          <div class="mx-auto max-w-5xl rounded-lg bg-base-100 p-4 shadow-sm">
            <EditorCanvas.canvas tree={@preview_tree} selected_id={@selected_id} />
          </div>
        </main>

        <aside
          :if={@right_sidebar_open?}
          id="section-builder-right-sidebar"
          class="flex min-h-0 flex-col overflow-hidden rounded-lg border border-base-300 bg-base-100"
        >
          <div class="flex items-center justify-between border-b border-base-300 p-3">
            <div>
              <h2 class="font-semibold">Properties</h2>
              <p class="text-xs text-base-content/60">{sidebar_subtitle(@right_sidebar_size)}</p>
            </div>
            <div class="flex items-center gap-1">
              <button
                id="section-builder-minimize-sidebar"
                type="button"
                phx-click="set_right_sidebar_size"
                phx-value-size="minimized"
                class="btn btn-ghost btn-xs btn-circle"
                aria-label="Minimize properties"
              >
                <.icon name="hero-minus" class="size-4" />
              </button>
              <button
                id="section-builder-maximize-sidebar"
                type="button"
                phx-click="set_right_sidebar_size"
                phx-value-size={
                  if(@right_sidebar_size == "maximized", do: "normal", else: "maximized")
                }
                class="btn btn-ghost btn-xs btn-circle"
                aria-label="Maximize properties"
              >
                <.icon name="hero-arrows-pointing-out" class="size-4" />
              </button>
              <button
                id="section-builder-close-sidebar"
                type="button"
                phx-click="close_right_sidebar"
                class="btn btn-ghost btn-xs btn-circle"
                aria-label="Close properties"
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>
            </div>
          </div>

          <.form
            :if={@right_sidebar_size != "minimized"}
            for={to_form(%{}, as: :node)}
            id="section-builder-form"
            phx-change="update_selected"
            class="min-h-0 flex-1 overflow-y-auto p-4"
          >
            <div>
              <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
                Selected element
              </h2>
              <%= if selected = selected_node(@tree, @selected_id) do %>
                <.selected_node_form node={selected} collection_fields={@collection_fields} />
              <% else %>
                <p class="mt-3 text-sm text-base-content/60">
                  Select a block in the canvas to edit text, links, media, and classes.
                </p>
              <% end %>
            </div>

            <div class="mt-5 flex justify-end gap-2">
              <button
                id="section-builder-delete-selected"
                type="button"
                phx-click="delete_selected"
                class="btn btn-ghost text-error"
              >
                Delete selected
              </button>
              <button
                id="section-builder-save-button"
                type="button"
                phx-click="save_section"
                class="btn btn-primary"
              >
                Save
              </button>
            </div>
          </.form>
        </aside>
      </section>
    </Layouts.tenant_admin>
    """
  end

  attr :node, :map, required: true
  attr :collection_fields, :list, default: []

  defp selected_node_form(assigns) do
    props = Map.get(assigns.node, "props", %{})
    classes = Map.get(assigns.node, "classes", %{})
    name = Map.get(assigns.node, "name", "")

    assigns =
      assigns
      |> assign(:props, props)
      |> assign(:classes, classes)
      |> assign(:name, name)
      |> assign(:bindable_props, bindable_props(name))

    ~H"""
    <div id={"section-builder-selected-#{@node["id"]}"} class="mt-3 grid gap-3">
      <div class="rounded-lg border border-base-300 bg-base-200/40 p-3">
        <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60">
          Data binding
        </p>
        <p class="mt-1 text-xs text-base-content/60">
          Type static text, or bind a property to a collection field.
        </p>
        <div :if={@collection_fields != [] and @bindable_props != []} class="mt-3 grid gap-2">
          <div :for={prop <- @bindable_props} class="grid gap-1">
            <p class="text-xs font-medium capitalize">{prop}</p>
            <div class="flex flex-wrap gap-1">
              <button
                :for={field <- @collection_fields}
                type="button"
                phx-click="bind_selected_prop"
                phx-value-prop={prop}
                phx-value-path={"item.payload.#{field.field_key}"}
                class="btn btn-xs btn-ghost border border-base-300"
              >
                {field.label}
              </button>
              <button
                type="button"
                phx-click="bind_selected_prop"
                phx-value-prop={prop}
                phx-value-path="item.slug"
                class="btn btn-xs btn-ghost border border-base-300"
              >
                Slug
              </button>
            </div>
          </div>
        </div>
        <p :if={@collection_fields == []} class="mt-3 text-xs text-base-content/50">
          Select a collection in the Source tab to enable field binding.
        </p>
      </div>

      <.input
        id="section-builder-selected-text"
        name="node[text]"
        type="textarea"
        label="Text"
        value={@props["text"] || ""}
        rows="3"
      />
      <.input
        id="section-builder-selected-href"
        name="node[href]"
        type="text"
        label="Link"
        value={@props["href"] || ""}
      />
      <.input
        id="section-builder-selected-src"
        name="node[src]"
        type="text"
        label="Image/video URL"
        value={@props["src"] || ""}
      />
      <.input
        id="section-builder-selected-alt"
        name="node[alt]"
        type="text"
        label="Alt text"
        value={@props["alt"] || ""}
      />
      <.input
        id="section-builder-selected-classes"
        name="node[classes]"
        type="textarea"
        label="Classes"
        value={@classes["custom"] || ""}
        rows="3"
      />
    </div>
    """
  end

  defp selected_node(tree, id) when is_binary(id), do: ContentTree.find_node(tree, id)
  defp selected_node(_tree, _id), do: nil

  attr :config_tab, :string, required: true
  attr :collections, :list, default: []
  attr :collection_fields, :list, default: []
  attr :settings, :map, default: %{}
  attr :source_config, :map, default: %{}
  attr :filters, :map, default: %{}
  attr :loop_settings, :map, default: %{}

  defp section_config_panel(assigns) do
    assigns =
      assigns
      |> assign(:collection_options, collection_options(assigns.collections))
      |> assign(:field_options, field_options(assigns.collection_fields))
      |> assign(:filter_rule, first_filter_rule(assigns.filters))

    ~H"""
    <section class="mb-4 overflow-hidden rounded-lg border border-base-300 bg-base-100 shadow-sm">
      <div class="flex flex-wrap items-center justify-between gap-3 border-b border-base-300 p-3">
        <div class="tabs tabs-boxed">
          <button
            :for={tab <- config_tabs()}
            id={"section-config-tab-#{tab.id}"}
            type="button"
            phx-click="set_config_tab"
            phx-value-tab={tab.id}
            class={["tab", @config_tab == tab.id && "tab-active"]}
          >
            {tab.label}
          </button>
        </div>

        <button
          id="section-config-save-button"
          type="button"
          phx-click="save_section"
          class="btn btn-primary btn-sm"
        >
          Save section
        </button>
      </div>

      <.form
        for={to_form(%{}, as: :section_config)}
        id="section-config-form"
        phx-change="update_section_config"
        class="grid gap-4 p-4"
      >
        <div :if={@config_tab == "source"} class="grid gap-4 md:grid-cols-3">
          <.input
            id="section-config-source-kind"
            name="section_config[source][kind]"
            type="select"
            label="Data source"
            value={@source_config["kind"] || "fixed"}
            options={[
              {"Fixed content", "fixed"},
              {"Collection", "collection"},
              {"Catalog", "catalog"}
            ]}
          />
          <.input
            id="section-config-collection"
            name="section_config[source][collection_slug]"
            type="select"
            label="Collection"
            value={@source_config["collection_slug"] || @source_config["collection_id"] || ""}
            options={@collection_options}
          />
          <.input
            id="section-config-sort-field"
            name="section_config[source][sort_field]"
            type="select"
            label="Sort field"
            value={get_in(@source_config, ["sort", "field"]) || "inserted_at"}
            options={
              [{"Created at", "inserted_at"}, {"Published at", "published_at"}, {"Title", "title"}] ++
                @field_options
            }
          />
          <.input
            id="section-config-sort-direction"
            name="section_config[source][sort_direction]"
            type="select"
            label="Sort order"
            value={get_in(@source_config, ["sort", "direction"]) || "desc"}
            options={[{"Newest / Z-A", "desc"}, {"Oldest / A-Z", "asc"}]}
          />
        </div>

        <div :if={@config_tab == "filters"} class="grid gap-4 md:grid-cols-3">
          <.input
            id="section-config-filter-field"
            name="section_config[filters][field]"
            type="select"
            label="Filter field"
            value={@filter_rule["field"] || ""}
            options={[{"No filter", ""}] ++ @field_options}
          />
          <.input
            id="section-config-filter-op"
            name="section_config[filters][op]"
            type="select"
            label="Condition"
            value={@filter_rule["op"] || "=="}
            options={[
              {"Is", "=="},
              {"Contains", "contains"},
              {"Greater than", ">"},
              {"At least", ">="},
              {"Less than", "<"},
              {"At most", "<="},
              {"Is not", "!="}
            ]}
          />
          <.input
            id="section-config-filter-value"
            name="section_config[filters][value]"
            type="text"
            label="Value"
            value={to_string(@filter_rule["value"] || "")}
          />
        </div>

        <div :if={@config_tab == "loop"} class="grid gap-4 md:grid-cols-4">
          <.input
            id="section-config-loop-enabled"
            name="section_config[loop][enabled]"
            type="select"
            label="Loop records"
            value={bool_string(@loop_settings["enabled"])}
            options={[{"Enabled", "true"}, {"Disabled", "false"}]}
          />
          <.input
            id="section-config-loop-limit"
            name="section_config[loop][limit]"
            type="number"
            label="Records"
            value={@loop_settings["limit"] || 6}
          />
          <.input
            id="section-config-loop-layout"
            name="section_config[loop][layout]"
            type="select"
            label="Layout"
            value={@loop_settings["layout"] || "grid"}
            options={[
              {"Grid", "grid"},
              {"Slider", "slider"},
              {"Carousel", "carousel"},
              {"Gallery", "gallery"},
              {"List", "list"}
            ]}
          />
          <.input
            id="section-config-loop-alias"
            name="section_config[loop][as]"
            type="text"
            label="Item alias"
            value={@loop_settings["as"] || "item"}
          />
        </div>

        <div :if={@config_tab == "settings"} class="grid gap-4 md:grid-cols-4">
          <.input
            id="section-config-type"
            name="section_config[settings][section_type]"
            type="select"
            label="Section type"
            value={@settings["section_type"] || "custom"}
            options={[
              {"Custom", "custom"},
              {"Hero", "hero"},
              {"CTA", "cta"},
              {"Slider", "slider"},
              {"Carousel", "carousel"},
              {"Gallery", "gallery"},
              {"Grid", "grid"}
            ]}
          />
          <.input
            id="section-config-variant"
            name="section_config[settings][variant]"
            type="text"
            label="Variant"
            value={@settings["variant"] || ""}
          />
          <.input
            id="section-config-transition"
            name="section_config[settings][transition]"
            type="select"
            label="Transition"
            value={@settings["transition"] || "slide"}
            options={[{"Slide", "slide"}, {"Fade", "fade"}, {"Snap", "snap"}, {"None", "none"}]}
          />
          <.input
            id="section-config-interval"
            name="section_config[settings][interval_ms]"
            type="number"
            label="Interval ms"
            value={@settings["interval_ms"] || 5000}
          />
        </div>
      </.form>
    </section>
    """
  end

  attr :tree, :list, required: true
  attr :selected_id, :string, default: nil

  defp layers_tree(assigns) do
    ~H"""
    <ul id="section-builder-layers" class="mt-3 space-y-1 text-sm">
      <.layers_node :for={node <- @tree} node={node} selected_id={@selected_id} depth={0} />
      <li
        :if={@tree == []}
        class="rounded-lg border border-dashed border-base-300 p-3 text-base-content/60"
      >
        No blocks yet.
      </li>
    </ul>
    """
  end

  attr :node, :map, required: true
  attr :selected_id, :string, default: nil
  attr :depth, :integer, default: 0

  defp layers_node(assigns) do
    assigns =
      assigns
      |> assign(:node_id, Map.get(assigns.node, "id", ""))
      |> assign(:name, Map.get(assigns.node, "name", "unknown"))
      |> assign(:children, safe_children(assigns.node))

    ~H"""
    <li>
      <button
        id={"section-builder-layer-#{@node_id}"}
        type="button"
        phx-click="select_element"
        phx-value-id={@node_id}
        phx-value-source="layers"
        class={[
          "block w-full rounded px-2 py-1.5 text-left transition hover:bg-base-200",
          @selected_id == @node_id && "bg-primary/10 text-primary"
        ]}
        style={"padding-left: #{@depth * 0.75 + 0.5}rem"}
      >
        {@name}
      </button>
      <ul :if={@children != []} class="space-y-1">
        <.layers_node
          :for={child <- @children}
          node={child}
          selected_id={@selected_id}
          depth={@depth + 1}
        />
      </ul>
    </li>
    """
  end

  defp safe_children(%{"children" => children}) when is_list(children), do: children
  defp safe_children(_node), do: []

  defp block_palette do
    [
      %{name: "section", label: "Section", icon: "hero-square-3-stack-3d"},
      %{name: "row", label: "Row", icon: "hero-bars-3"},
      %{name: "column", label: "Column", icon: "hero-rectangle-group"},
      %{name: "heading", label: "Heading", icon: "hero-h1"},
      %{name: "paragraph", label: "Paragraph", icon: "hero-document-text"},
      %{name: "image", label: "Image", icon: "hero-photo"},
      %{name: "button", label: "Button", icon: "hero-cursor-arrow-rays"},
      %{name: "loop", label: "Collection loop", icon: "hero-arrow-path-rounded-square"}
    ]
  end

  defp new_node("section"), do: container_node("section", %{"custom" => "py-12"})
  defp new_node("row"), do: container_node("row", %{"custom" => "mx-auto grid max-w-7xl gap-6"})
  defp new_node("column"), do: container_node("column", %{"custom" => "grid gap-4"})

  defp new_node("heading") do
    leaf_node("heading", %{"text" => "Editable {{title}}"}, %{"custom" => "text-4xl font-bold"})
  end

  defp new_node("paragraph") do
    leaf_node(
      "paragraph",
      %{"text" => "Write static copy or use {{description}} from a data source."},
      %{
        "custom" => "text-base-content/70"
      }
    )
  end

  defp new_node("image") do
    leaf_node("image", %{"src" => "", "alt" => ""}, %{
      "custom" => "aspect-video rounded-lg object-cover"
    })
  end

  defp new_node("button") do
    leaf_node("button", %{"text" => "Learn more", "href" => "#"}, %{"custom" => "btn btn-primary"})
  end

  defp new_node("loop") do
    %{
      "type" => "component",
      "name" => "loop",
      "id" => node_id("loop"),
      "props" => %{"source" => "collection_results", "as" => "item"},
      "classes" => %{"custom" => "grid gap-4 md:grid-cols-3"},
      "children" => [
        container_node("column", %{"custom" => "card bg-base-100 p-5 shadow-sm"})
        |> Map.put("children", [
          leaf_node("heading", %{"text" => "{{item.title}}", "level" => "3"}, %{
            "custom" => "text-xl font-semibold"
          }),
          leaf_node("paragraph", %{"text" => "{{item.payload.description}}"}, %{
            "custom" => "mt-2 text-base-content/70"
          }),
          leaf_node("button", %{"text" => "Open", "href" => "/{{item.slug}}"}, %{
            "custom" => "btn btn-primary btn-sm mt-4"
          })
        ])
      ]
    }
  end

  defp new_node(_name), do: new_node("paragraph")

  defp container_node(name, classes) do
    %{
      "type" => "component",
      "name" => name,
      "id" => node_id(name),
      "props" => %{},
      "classes" => classes,
      "children" => []
    }
  end

  defp leaf_node(name, props, classes) do
    %{
      "type" => "component",
      "name" => name,
      "id" => node_id(name),
      "props" => props,
      "classes" => classes
    }
  end

  defp node_id(prefix), do: "#{prefix}-#{Ecto.UUID.generate()}"

  defp error_text(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, _opts} -> message end)
    |> Enum.map_join(", ", fn {field, messages} -> "#{field}: #{Enum.join(messages, ", ")}" end)
  end

  defp section_builder_grid_class(assigns) do
    sidebar_size = assigns[:right_sidebar_size]
    sidebar_open? = assigns[:right_sidebar_open?]

    columns =
      cond do
        not sidebar_open? -> "lg:grid-cols-[16rem_1fr]"
        sidebar_size == "minimized" -> "lg:grid-cols-[16rem_1fr_5rem]"
        sidebar_size == "maximized" -> "lg:grid-cols-[16rem_minmax(0,0.85fr)_minmax(28rem,0.9fr)]"
        true -> "lg:grid-cols-[16rem_1fr_24rem]"
      end

    ["grid min-h-[72vh] gap-4", columns]
  end

  defp normalize_sidebar_size("minimized"), do: "normal"
  defp normalize_sidebar_size("maximized"), do: "maximized"
  defp normalize_sidebar_size(_size), do: "normal"

  defp sidebar_subtitle("minimized"), do: "Minimized"
  defp sidebar_subtitle("maximized"), do: "Element inspector"
  defp sidebar_subtitle(_size), do: "Selected element"

  defp collection_fields(tenant, source_config) do
    collection = source_config["collection_slug"] || source_config["collection_id"]

    if is_binary(collection) and collection != "" do
      Collections.list_collection_fields(tenant, collection)
    else
      []
    end
  rescue
    Ecto.NoResultsError -> []
  end

  defp update_source_config(existing, params) do
    kind = params["kind"] || existing["kind"] || "fixed"
    collection_slug = params["collection_slug"] || existing["collection_slug"] || ""
    sort_field = params["sort_field"] || get_in(existing, ["sort", "field"]) || "inserted_at"
    sort_direction = params["sort_direction"] || get_in(existing, ["sort", "direction"]) || "desc"

    %{
      "kind" => kind,
      "collection_slug" => collection_slug,
      "sort" => %{"field" => sort_field, "direction" => sort_direction}
    }
    |> maybe_drop_collection(kind)
  end

  defp maybe_drop_collection(source_config, kind) when kind in ["collection", "catalog"],
    do: source_config

  defp maybe_drop_collection(source_config, _kind),
    do: Map.drop(source_config, ["collection_slug"])

  defp update_filters(params) do
    field = params["field"] || ""

    if field == "" do
      %{"rules" => []}
    else
      %{
        "rules" => [
          %{"field" => field, "op" => params["op"] || "==", "value" => params["value"] || ""}
        ]
      }
    end
  end

  defp update_loop_settings(existing, params) do
    %{
      "enabled" => parse_bool(params["enabled"], existing["enabled"] || false),
      "limit" => parse_integer(params["limit"], existing["limit"] || 6),
      "layout" => params["layout"] || existing["layout"] || "grid",
      "as" => params["as"] || existing["as"] || "item"
    }
  end

  defp update_settings(existing, params) do
    existing
    |> Map.merge(%{
      "section_type" => params["section_type"] || existing["section_type"] || "custom",
      "variant" => params["variant"] || existing["variant"] || "",
      "transition" => params["transition"] || existing["transition"] || "slide",
      "interval_ms" => parse_integer(params["interval_ms"], existing["interval_ms"] || 5000)
    })
  end

  defp config_tabs do
    [
      %{id: "source", label: "Source"},
      %{id: "filters", label: "Filters"},
      %{id: "loop", label: "Loop"},
      %{id: "settings", label: "Settings"}
    ]
  end

  defp collection_options(collections) do
    [{"Choose collection", ""}] ++ Enum.map(collections, &{&1.name, &1.slug})
  end

  defp field_options(fields), do: Enum.map(fields, &{&1.label, &1.field_key})

  defp first_filter_rule(%{"rules" => [rule | _rest]}) when is_map(rule), do: rule
  defp first_filter_rule(_filters), do: %{}

  defp bool_string(true), do: "true"
  defp bool_string("true"), do: "true"
  defp bool_string(_value), do: "false"

  defp parse_bool(value, _default) when value in [true, "true", "1", 1], do: true
  defp parse_bool(value, _default) when value in [false, "false", "0", 0], do: false
  defp parse_bool(_value, default), do: default

  defp parse_integer(value, _default) when is_integer(value), do: value

  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _other -> default
    end
  end

  defp parse_integer(_value, default), do: default

  defp bindable_props("heading"), do: ["text"]
  defp bindable_props("paragraph"), do: ["text"]
  defp bindable_props("blockquote"), do: ["text"]
  defp bindable_props("button"), do: ["text", "href", "title"]
  defp bindable_props("anchor"), do: ["text", "href", "title"]
  defp bindable_props("image"), do: ["src", "alt", "href"]
  defp bindable_props("video"), do: ["src", "title"]
  defp bindable_props(_name), do: []

  defp assign_preview_tree(socket) do
    assign(socket, :preview_tree, preview_tree(socket))
  end

  defp preview_tree(socket) do
    bindings = preview_bindings(socket)
    preview_nodes(socket.assigns.tree || [], bindings)
  end

  defp preview_bindings(socket) do
    item = sample_collection_item(socket)
    item_alias = socket.assigns.loop_settings["as"] || "item"
    collection_results = if is_map(item), do: [item], else: []

    %{
      "collection_results" => collection_results,
      "item" => item || %{},
      item_alias => item || %{}
    }
    |> maybe_merge_item(item)
  end

  defp maybe_merge_item(bindings, item) when is_map(item), do: Map.merge(bindings, item)
  defp maybe_merge_item(bindings, _item), do: bindings

  defp sample_collection_item(socket) do
    source_config = socket.assigns.source_config || %{}
    collection = source_config["collection_id"] || source_config["collection_slug"]

    if collection_source?(source_config) and is_binary(collection) and collection != "" do
      filters = get_in(socket.assigns.filters || %{}, ["rules"]) || source_config["filters"] || []
      sort = source_config["sort"]

      socket.assigns.current_tenant
      |> Collections.list_entries(collection,
        status: "all",
        filters: filters,
        sort: sort,
        limit: 1
      )
      |> List.first()
      |> entry_binding()
    end
  rescue
    Ecto.NoResultsError -> nil
  end

  defp collection_source?(%{"kind" => kind}) when kind in ["collection", "catalog"], do: true

  defp collection_source?(%{"collection_id" => collection_id}) when is_binary(collection_id),
    do: true

  defp collection_source?(%{"collection_slug" => collection_slug})
       when is_binary(collection_slug),
       do: true

  defp collection_source?(_source_config), do: false

  defp entry_binding(%CollectionItem{} = entry) do
    payload = entry.payload || %{}

    %{
      "id" => entry.id,
      "title" => entry.title,
      "slug" => entry.slug,
      "status" => entry.status,
      "payload" => payload,
      "inserted_at" => datetime_to_string(entry.inserted_at),
      "updated_at" => datetime_to_string(entry.updated_at),
      "published_at" => datetime_to_string(entry.published_at)
    }
    |> Map.merge(payload)
  end

  defp entry_binding(_entry), do: nil

  defp preview_nodes(nodes, bindings) when is_list(nodes) do
    Enum.map(nodes, &preview_node(&1, bindings))
  end

  defp preview_nodes(_nodes, _bindings), do: []

  defp preview_node(%{"name" => "loop"} = node, bindings) do
    item = bindings |> Map.get("collection_results", []) |> List.first()
    item_alias = node |> node_map("props") |> Map.get("as", Map.get(bindings, "as", "item"))

    loop_bindings =
      if is_map(item) do
        bindings
        |> Map.put("item", item)
        |> Map.put(item_alias, item)
        |> maybe_merge_item(item)
      else
        bindings
      end

    node
    |> interpolate_node(loop_bindings)
    |> put_preview_children(preview_nodes(children(node), loop_bindings))
  end

  defp preview_node(node, bindings) when is_map(node) do
    node
    |> interpolate_node(bindings)
    |> put_preview_children(preview_nodes(children(node), bindings))
  end

  defp preview_node(node, _bindings), do: node

  defp put_preview_children(node, children) do
    if Map.has_key?(node, "children") do
      Map.put(node, "children", children)
    else
      node
    end
  end

  defp preview_prop_value(socket, value), do: interpolate_value(value, preview_bindings(socket))

  defp maybe_push_text_update(socket, id, %{"text" => value}) when is_binary(id) do
    push_event(socket, "builder:update_text_node", %{
      id: id,
      property: "text",
      value: preview_prop_value(socket, value)
    })
  end

  defp maybe_push_text_update(socket, _id, _props), do: socket

  defp push_preview_text_updates(socket) do
    text_nodes = collect_preview_text_nodes(socket.assigns.preview_tree || [])

    if text_nodes == %{} do
      socket
    else
      push_event(socket, "builder:update_text_nodes", %{nodes: text_nodes})
    end
  end

  defp collect_preview_text_nodes(nodes) when is_list(nodes) do
    Enum.reduce(nodes, %{}, fn node, acc ->
      Map.merge(acc, collect_preview_text_node(node))
    end)
  end

  defp collect_preview_text_nodes(_nodes), do: %{}

  defp collect_preview_text_node(%{"id" => id, "name" => name, "props" => props} = node)
       when name in ["heading", "paragraph", "blockquote", "button", "anchor"] and is_map(props) do
    node
    |> children()
    |> collect_preview_text_nodes()
    |> Map.put(id, %{"text" => props["text"] || ""})
  end

  defp collect_preview_text_node(node) when is_map(node) do
    node
    |> children()
    |> collect_preview_text_nodes()
  end

  defp collect_preview_text_node(_node), do: %{}

  defp interpolate_node(node, bindings) do
    node
    |> Map.update("props", %{}, &interpolate_value(&1, bindings))
    |> Map.update("classes", %{}, &interpolate_value(&1, bindings))
  end

  defp interpolate_value(value, bindings) when is_binary(value) do
    Regex.replace(~r/\{\{\s*([^}]+?)\s*\}\}/, value, fn _match, path ->
      bindings
      |> get_binding_path(path)
      |> binding_to_string()
    end)
  end

  defp interpolate_value(value, bindings) when is_map(value) do
    Map.new(value, fn {key, child_value} -> {key, interpolate_value(child_value, bindings)} end)
  end

  defp interpolate_value(value, bindings) when is_list(value) do
    Enum.map(value, &interpolate_value(&1, bindings))
  end

  defp interpolate_value(value, _bindings), do: value

  defp get_binding_path(bindings, path) when is_binary(path) do
    path
    |> String.split(".", trim: true)
    |> Enum.reduce_while(bindings, fn key, acc ->
      case acc do
        map when is_map(map) -> {:cont, Map.get(map, key)}
        _other -> {:halt, nil}
      end
    end)
  rescue
    ArgumentError -> nil
  end

  defp binding_to_string(nil), do: ""
  defp binding_to_string(value) when is_binary(value), do: value
  defp binding_to_string(value) when is_integer(value), do: Integer.to_string(value)
  defp binding_to_string(value) when is_float(value), do: Float.to_string(value)
  defp binding_to_string(value) when is_boolean(value), do: to_string(value)
  defp binding_to_string(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp binding_to_string(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp binding_to_string(%Date{} = value), do: Date.to_iso8601(value)
  defp binding_to_string(value) when is_map(value), do: Map.get(value, "url", "")
  defp binding_to_string(_value), do: ""

  defp datetime_to_string(nil), do: nil
  defp datetime_to_string(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp datetime_to_string(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)

  defp children(%{"children" => children}) when is_list(children), do: children
  defp children(_node), do: []

  defp node_map(node, key) when is_map(node) do
    case Map.get(node, key) do
      value when is_map(value) -> value
      _other -> %{}
    end
  end

  defp node_map(_node, _key), do: %{}

  defp maybe_clear_selection(socket, id) do
    if socket.assigns.selected_id == id do
      assign(socket, :selected_id, nil)
    else
      socket
    end
  end
end
