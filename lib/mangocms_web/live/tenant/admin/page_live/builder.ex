defmodule MangoCMSWeb.Tenant.Admin.PageLive.Builder do
  @moduledoc """
  Tenant admin visual page builder backed by the content-tree AST.
  """

  use MangoCMSWeb, :live_view

  alias MangoCMS.ContentTree
  alias MangoCMS.Tenant.Pages
  alias MangoCMS.Tenant.Pages.Page
  alias MangoCMS.Uploads
  alias MangoCMSWeb.AdminGuard
  alias MangoCMSWeb.Builder.Registry
  alias MangoCMSWeb.Live.Admin.EditorCanvas

  @viewport_options [
    {"Desktop", "desktop", "hero-computer-desktop"},
    {"Tablet", "tablet", "hero-device-tablet"},
    {"Mobile", "mobile", "hero-device-phone-mobile"}
  ]

  @legacy_palette_items [
    %{name: "loop", label: "Loop (repeat items)", icon: "hero-arrow-path", variant: "default"},
    %{name: "anchor", label: "Anchor Link", icon: "hero-link", variant: "default"},
    %{name: "dynamic_form", label: "Simple Form", icon: "hero-envelope", variant: "default"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_pages) do
      {:ok, socket} ->
        {:ok,
         allow_upload(socket, :builder_asset,
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
  def handle_params(%{"id" => id}, _url, socket) do
    tenant = socket.assigns.current_tenant
    page = Pages.get_page!(tenant, id)
    tree = initial_tree(page)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:page_form, to_form(page_form_params(page), as: :page))
     |> assign(:tree, tree)
     |> assign(:selected_id, first_node_id(tree))
     |> assign(:history, [tree])
     |> assign(:history_index, 0)
     |> assign(:clipboard, nil)
     |> assign(:viewport, "desktop")
     |> assign(:viewport_options, @viewport_options)
     |> assign(:left_tab, "components")
     |> assign(:blocks_collapsed, true)
     |> assign(:palette_query, "")
     |> assign(:section_query, "")
     |> assign(:current_version, page.content_tree_version || 1)
     |> assign(:sections, Pages.list_sections(tenant))
     |> assign(:versions, Pages.list_page_versions(tenant, page))
     |> assign(:show_versions?, false)
     |> assign(:right_sidebar_open?, true)
     |> assign(:manual_version_label, "")}
  end

  # ---------------------------------------------------------------------------
  # Page and version actions
  # ---------------------------------------------------------------------------

  @impl true
  def handle_event("save_page", %{"page" => page_params}, socket) do
    tenant = socket.assigns.current_tenant
    page = socket.assigns.page

    attrs =
      page_params
      |> normalize_page_params(page)
      |> Map.put("content_tree", socket.assigns.tree)

    case Pages.save_page_with_lock(
           tenant,
           page,
           attrs,
           socket.assigns.current_version,
           socket.assigns.current_user
         ) do
      {:ok, page} ->
        {:noreply,
         socket
         |> assign_page_state(page)
         |> put_flash(:info, "Page saved")}

      {:error, :stale} ->
        {:noreply,
         put_flash(socket, :error, "This page changed in another tab. Reload before saving.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :page_form, to_form(changeset))}
    end
  end

  def handle_event("save_manual_version", %{"version" => %{"label" => label}}, socket) do
    {:ok, _version} =
      Pages.create_page_version(
        socket.assigns.current_tenant,
        socket.assigns.page,
        "manual",
        blank_to_nil(label),
        socket.assigns.current_user,
        %{change_summary: "Manual version saved"}
      )

    {:noreply,
     socket
     |> assign(:manual_version_label, "")
     |> reload_versions()
     |> put_flash(:info, "Version saved")}
  end

  def handle_event("restore_version", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    version = Pages.get_page_version!(tenant, id)

    {:ok, page} =
      Pages.restore_page_to_version(
        tenant,
        socket.assigns.page,
        version,
        socket.assigns.current_user
      )

    tree = page.content_tree || []

    {:noreply,
     socket
     |> assign_page_state(page)
     |> assign(:tree, tree)
     |> assign_history(tree)
     |> assign(:selected_id, first_node_id(tree))
     |> put_flash(:info, "Draft restored from version #{version.version_number}")}
  end

  def handle_event("toggle_versions", _params, socket) do
    {:noreply,
     socket
     |> assign(:right_sidebar_open?, true)
     |> update(:show_versions?, &(!&1))}
  end

  def handle_event("close_right_sidebar", _params, socket) do
    {:noreply, assign(socket, right_sidebar_open?: false, show_versions?: false)}
  end

  # ---------------------------------------------------------------------------
  # Canvas tree mutations
  # ---------------------------------------------------------------------------

  def handle_event("select_element", %{"id" => id} = params, socket) do
    source = Map.get(params, "source", "canvas")

    {:noreply,
     socket
     |> assign(:selected_id, id)
     |> assign(:left_tab, if(source == "canvas", do: "layers", else: socket.assigns.left_tab))
     |> assign(:right_sidebar_open?, true)
     |> assign(:show_versions?, false)
     |> push_event("builder:focus-node", %{id: id, source: source})}
  end

  def handle_event("set_viewport", %{"viewport" => viewport}, socket) do
    if viewport in Enum.map(@viewport_options, &elem(&1, 1)) do
      {:noreply, assign(socket, :viewport, viewport)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("search_palette", %{"q" => query}, socket) do
    {:noreply, assign(socket, :palette_query, query || "")}
  end

  def handle_event("search_sections", %{"q" => query}, socket) do
    {:noreply, assign(socket, :section_query, query || "")}
  end

  def handle_event("set_left_tab", %{"tab" => tab}, socket)
      when tab in ~w(components sections layers) do
    {:noreply, assign(socket, :left_tab, tab)}
  end

  def handle_event("toggle_blocks", _params, socket) do
    {:noreply, update(socket, :blocks_collapsed, &(!&1))}
  end

  def handle_event("add_palette_node", %{"name" => name} = params, socket) do
    variant = Map.get(params, "variant", "default")
    target_id = socket.assigns.selected_id || "root"
    position = if target_id == "root", do: :into, else: :into

    socket
    |> add_node_to_tree(name, variant, target_id, position)
    |> noreply()
  end

  def handle_event(
        "drop_node",
        %{"dragged_id" => dragged_id, "target_id" => target_id} = params,
        socket
      ) do
    position = parse_position(Map.get(params, "position"))
    tree = socket.assigns.tree

    target_name = target_container_name(tree, target_id, position)
    dragged_name = target_name(tree, dragged_id)

    cond do
      target_id == "root" and position == :into ->
        socket
        |> mutate_tree(ContentTree.move_node(tree, dragged_id, "root", :into))
        |> noreply()

      EditorCanvas.accepts?(target_name, dragged_name) ->
        socket
        |> mutate_tree(ContentTree.move_node(tree, dragged_id, target_id, position))
        |> noreply()

      true ->
        socket
        |> put_flash(
          :error,
          "#{human_name(dragged_name)} cannot be dropped into #{human_name(target_name)}"
        )
        |> noreply()
    end
  end

  def handle_event(
        "drop_palette_node",
        %{"name" => name, "target_id" => target_id} = params,
        socket
      ) do
    variant = Map.get(params, "variant", "default")
    position = parse_position(Map.get(params, "position"))

    socket
    |> add_node_to_tree(name, variant, target_id, position)
    |> noreply()
  end

  def handle_event("delete_node", %{"id" => id}, socket) do
    tree = ContentTree.delete_node(socket.assigns.tree, id)

    socket
    |> mutate_tree(tree)
    |> assign(:selected_id, first_node_id(tree))
    |> noreply()
  end

  def handle_event("copy_node", %{"id" => id}, socket) do
    {:noreply, assign(socket, :clipboard, ContentTree.find_node(socket.assigns.tree, id))}
  end

  def handle_event("duplicate_node", %{"id" => id}, socket) do
    case ContentTree.find_node(socket.assigns.tree, id) do
      nil ->
        {:noreply, socket}

      node ->
        duplicate = deep_copy_with_new_ids(node)
        tree = ContentTree.insert_node(socket.assigns.tree, id, duplicate, :after)

        socket
        |> mutate_tree(tree)
        |> assign(:selected_id, Map.get(duplicate, "id"))
        |> noreply()
    end
  end

  def handle_event("paste_node", _params, %{assigns: %{clipboard: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("paste_node", _params, socket) do
    clipboard =
      socket.assigns.clipboard
      |> deep_copy_with_new_ids()

    target_id = socket.assigns.selected_id || "root"
    socket |> insert_valid_node(clipboard, target_id, :into) |> noreply()
  end

  def handle_event("undo", _params, socket), do: {:noreply, travel_history(socket, -1)}
  def handle_event("redo", _params, socket), do: {:noreply, travel_history(socket, 1)}

  # ---------------------------------------------------------------------------
  # Inspector and contenteditable bridge
  # ---------------------------------------------------------------------------

  def handle_event("update_selected_node", %{"node" => node_params}, socket) do
    selected_id = socket.assigns.selected_id
    props = safe_map(Map.get(node_params, "props"))
    classes = normalize_inspector_classes(node_params)

    tree =
      socket.assigns.tree
      |> ContentTree.update_node_props(selected_id, props)
      |> ContentTree.update_node_classes(selected_id, classes)

    {:noreply, mutate_tree(socket, tree)}
  end

  def handle_event("add_class", %{"class" => class_name}, socket) do
    socket
    |> update_selected_class_text(&add_class_token(&1, class_name))
    |> noreply()
  end

  def handle_event("remove_class", %{"class" => class_name}, socket) do
    socket
    |> update_selected_class_text(&remove_class_token(&1, class_name))
    |> noreply()
  end

  def handle_event(
        "update_text_property",
        %{"id" => id, "property" => property, "value" => value},
        socket
      ) do
    tree = ContentTree.update_node_props(socket.assigns.tree, id, %{property => value || ""})
    {:noreply, mutate_tree(socket, tree)}
  end

  def handle_event("save_asset", _params, socket) do
    selected_id = socket.assigns.selected_id

    uploaded_paths =
      consume_uploaded_entries(socket, :builder_asset, fn meta, entry ->
        {:ok,
         Uploads.store_live_upload!(entry, meta, {:tenant, socket.assigns.current_tenant},
           type: ["pages", socket.assigns.page.id, "images"]
         )}
      end)

    case uploaded_paths do
      [path | _rest] ->
        tree = ContentTree.update_node_props(socket.assigns.tree, selected_id, %{"src" => path})
        {:noreply, mutate_tree(socket, tree)}

      [] ->
        {:noreply, socket}
    end
  end

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={"Builder: #{@page.title}"}
      subtitle="AST page builder with reusable blocks, version snapshots, and public-safe rendering."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:pages}
    >
      <:actions>
        <.link id="builder-back-button" navigate={~p"/admin/pages"} class="btn btn-ghost">
          <.icon name="hero-arrow-left" class="size-4" /> Pages
        </.link>
        <.link
          :if={@page.status == "published"}
          id="builder-view-public-button"
          href={~p"/#{@page.slug}"}
          class="btn btn-ghost"
        >
          <.icon name="hero-eye" class="size-4" /> View
        </.link>
        <button id="builder-undo-button" type="button" phx-click="undo" class="btn btn-ghost">
          <.icon name="hero-arrow-uturn-left" class="size-4" /> Undo
        </button>
        <button id="builder-redo-button" type="button" phx-click="redo" class="btn btn-ghost">
          <.icon name="hero-arrow-uturn-right" class="size-4" /> Redo
        </button>
        <button
          id="builder-toggle-versions-button"
          type="button"
          phx-click="toggle_versions"
          class="btn btn-ghost"
        >
          <.icon name="hero-clock" class="size-4" /> Versions
        </button>
        <button
          id="builder-save-page-button"
          type="submit"
          form="ast-builder-page-form"
          class="btn btn-primary"
        >
          <.icon name="hero-check" class="size-4" /> Save
        </button>
      </:actions>

      <section
        id="page-builder"
        phx-hook="AstBuilderCanvas"
        class={[
          "grid h-[calc(100vh-10rem)] min-h-[38rem] gap-3 overflow-hidden",
          @right_sidebar_open? && "grid-cols-[16rem_minmax(0,1fr)_24rem]",
          !@right_sidebar_open? && "grid-cols-[16rem_minmax(0,1fr)]"
        ]}
      >
        <aside
          id="builder-palette"
          class="flex h-full min-h-0 flex-col overflow-hidden rounded-lg border border-base-300 bg-base-100"
        >
          <div class="border-b border-base-300 p-3">
            <div class="join w-full">
              <button
                id="builder-left-tab-components"
                type="button"
                phx-click="set_left_tab"
                phx-value-tab="components"
                class={["btn join-item btn-sm flex-1", @left_tab == "components" && "btn-active"]}
                title="Components"
              >
                <.icon name="hero-squares-plus" class="size-4" />
              </button>
              <button
                id="builder-left-tab-sections"
                type="button"
                phx-click="set_left_tab"
                phx-value-tab="sections"
                class={["btn join-item btn-sm flex-1", @left_tab == "sections" && "btn-active"]}
                title="Sections"
              >
                <.icon name="hero-rectangle-stack" class="size-4" />
              </button>
              <button
                id="builder-left-tab-layers"
                type="button"
                phx-click="set_left_tab"
                phx-value-tab="layers"
                class={["btn join-item btn-sm flex-1", @left_tab == "layers" && "btn-active"]}
                title="Layers"
              >
                <.icon name="hero-list-bullet" class="size-4" />
              </button>
            </div>
            <p class="mt-2 text-center text-xs font-medium text-base-content/50">
              {cond do
                @left_tab == "components" -> "Components"
                @left_tab == "sections" -> "Sections"
                true -> "Layers"
              end}
            </p>
          </div>

          <div :if={@left_tab == "components"} class="flex min-h-0 flex-1 flex-col">
            <div class="border-b border-base-300 p-3">
              <label class="input input-bordered input-sm flex items-center gap-2">
                <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
                <input
                  id="builder-palette-search"
                  type="search"
                  name="q"
                  value={@palette_query}
                  phx-keyup="search_palette"
                  placeholder="Search components"
                  class="grow"
                />
              </label>
              <button
                id="builder-toggle-blocks-button"
                type="button"
                phx-click="toggle_blocks"
                class="btn btn-ghost btn-xs mt-3 w-full justify-between"
              >
                <span>
                  {if @blocks_collapsed,
                    do: "Expand component groups",
                    else: "Collapse component groups"}
                </span>
                <.icon
                  name={if(@blocks_collapsed, do: "hero-chevron-down", else: "hero-chevron-up")}
                  class="size-4"
                />
              </button>
            </div>

            <div class="min-h-0 flex-1 overflow-y-auto p-3">
              <.palette
                groups={filtered_palette(@palette_query)}
                collapsed={@blocks_collapsed}
              />
            </div>
          </div>

          <div :if={@left_tab == "sections"} class="flex min-h-0 flex-1 flex-col">
            <div class="border-b border-base-300 p-3">
              <label class="input input-bordered input-sm flex items-center gap-2">
                <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
                <input
                  id="builder-section-search"
                  type="search"
                  name="q"
                  value={@section_query}
                  phx-keyup="search_sections"
                  placeholder="Search sections"
                  class="grow"
                />
              </label>
              <p class="mt-2 text-xs text-base-content/60">
                Sections are reusable blocks. Static and dynamic sections are both inserted from here.
              </p>
            </div>
            <div class="min-h-0 flex-1 overflow-y-auto p-3">
              <.section_ref_picker sections={filtered_sections(@sections, @section_query)} />
            </div>
          </div>

          <div :if={@left_tab == "layers"} class="flex min-h-0 flex-1 flex-col">
            <div class="border-b border-base-300 p-3">
              <h3 class="text-sm font-semibold">Layers</h3>
              <p class="mt-1 text-xs text-base-content/60">
                Select any node to focus it and show its properties.
              </p>
            </div>
            <div class="min-h-0 flex-1 overflow-y-auto p-3">
              <.layers_tree tree={@tree} selected_id={@selected_id} />
            </div>
          </div>
        </aside>

        <main class="flex min-h-0 flex-col overflow-hidden rounded-lg border border-base-300 bg-base-200">
          <.form
            for={@page_form}
            id="ast-builder-page-form"
            phx-submit="save_page"
            class="border-b border-base-300 bg-base-100 p-4"
          >
            <div class="grid gap-3 lg:grid-cols-[1fr_12rem_10rem]">
              <.input field={@page_form[:title]} label="Title" />
              <.input field={@page_form[:slug]} label="Slug" />
              <.input
                field={@page_form[:status]}
                type="select"
                label="Status"
                options={Page.status_options()}
              />
            </div>
            <div class="mt-3 grid gap-3 lg:grid-cols-2">
              <.builder_input
                id="builder-page-subtitle"
                name="page[seo][subtitle]"
                label="Subtitle"
                value={page_seo(@page, "subtitle")}
              />
              <.builder_input
                id="builder-page-seo-description"
                name="page[seo][description]"
                label="SEO description"
                value={page_seo(@page, "description")}
              />
            </div>
          </.form>

          <div class="flex items-center justify-between border-b border-base-300 bg-base-100 px-4 py-3">
            <div class="join">
              <button
                :for={{label, value, icon} <- @viewport_options}
                id={"builder-viewport-#{value}"}
                type="button"
                phx-click="set_viewport"
                phx-value-viewport={value}
                class={["btn join-item btn-sm", @viewport == value && "btn-active"]}
              >
                <.icon name={icon} class="size-4" /> {label}
              </button>
            </div>
            <p class="text-xs text-base-content/60">
              Version {@current_version} · {length(@tree)} root blocks
            </p>
          </div>

          <div class="min-h-0 flex-1 overflow-auto p-3">
            <div id="builder-canvas-frame" class={viewport_class(@viewport)}>
              <EditorCanvas.canvas tree={@tree} selected_id={@selected_id} />
            </div>
          </div>
        </main>

        <aside
          :if={@right_sidebar_open?}
          id="builder-inspector-sidebar"
          class="flex h-full min-h-0 flex-col overflow-hidden rounded-lg border border-base-300 bg-base-100"
        >
          <%= if @show_versions? do %>
            <.version_history
              versions={@versions}
              tree={@tree}
              manual_version_label={@manual_version_label}
            />
          <% else %>
            <.inspector
              selected_node={selected_node(@tree, @selected_id)}
              clipboard={@clipboard}
              uploads={@uploads}
            />
          <% end %>
        </aside>
      </section>
    </Layouts.tenant_admin>
    """
  end

  attr(:groups, :list, required: true)
  attr(:collapsed, :boolean, default: false)

  defp palette(assigns) do
    ~H"""
    <div class="space-y-3">
      <details
        :for={group <- @groups}
        open={!@collapsed}
        class="collapse collapse-arrow border border-base-300 bg-base-100"
      >
        <summary class="collapse-title min-h-0 py-3 text-sm font-semibold">{group.label}</summary>
        <div class="collapse-content grid gap-2">
          <button
            :for={item <- group.items}
            id={"builder-add-#{item.name}-#{item.variant}"}
            type="button"
            draggable="true"
            data-palette-name={item.name}
            data-palette-variant={item.variant}
            phx-click="add_palette_node"
            phx-value-name={item.name}
            phx-value-variant={item.variant}
            class="btn btn-ghost justify-start"
          >
            <.icon name={item.icon} class="size-4" /> {item.label}
          </button>
        </div>
      </details>
    </div>
    """
  end

  attr(:sections, :list, default: [])

  defp section_ref_picker(assigns) do
    assigns = assign(assigns, :groups, section_ref_groups(assigns.sections))

    ~H"""
    <div class="space-y-3">
      <details
        :for={{group, sections} <- @groups}
        open
        class="collapse collapse-arrow border border-base-300 bg-base-100"
      >
        <summary class="collapse-title min-h-0 py-3 text-sm font-semibold">
          <span>{group}</span>
          <span class="ml-2 text-xs font-normal text-base-content/50">{length(sections)}</span>
        </summary>
        <div class="collapse-content grid gap-2">
          <button
            :for={section <- sections}
            id={"builder-add-section-#{section.id}"}
            type="button"
            draggable="true"
            data-palette-name="section_ref"
            data-palette-variant={section.id}
            phx-click="add_palette_node"
            phx-value-name="section_ref"
            phx-value-variant={section.id}
            class="rounded-lg border border-base-300 bg-base-100 p-3 text-left transition hover:border-primary hover:bg-primary/5"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold">{section.name}</p>
                <p class="mt-1 text-xs text-base-content/60">
                  {section_template_label(section)} · {section_mode_label(section)}
                </p>
                <p class="mt-1 text-xs text-base-content/60">
                  {section_loop_label(section)}
                </p>
              </div>
              <span class={section_mode_badge(section)}>{section.mode}</span>
            </div>
          </button>
        </div>
      </details>

      <p
        :if={@sections == []}
        class="rounded-lg border border-dashed border-base-300 p-4 text-sm text-base-content/60"
      >
        No sections match your search.
      </p>
    </div>
    """
  end

  attr(:tree, :list, required: true)
  attr(:selected_id, :string, default: nil)

  defp layers_tree(assigns) do
    ~H"""
    <ul class="mt-3 space-y-1 text-sm">
      <.layers_node :for={node <- @tree} node={node} selected_id={@selected_id} depth={0} />
    </ul>
    """
  end

  attr(:node, :map, required: true)
  attr(:selected_id, :string, default: nil)
  attr(:depth, :integer, default: 0)

  defp layers_node(assigns) do
    assigns =
      assigns
      |> assign(:node_id, Map.get(assigns.node, "id", ""))
      |> assign(:name, Map.get(assigns.node, "name", "unknown"))
      |> assign(:children, Map.get(assigns.node, "children", []))
      |> assign(:accepted_types, accepted_types(Map.get(assigns.node, "name", "unknown")))

    ~H"""
    <li
      id={"page-builder-layer-row-#{@node_id}"}
      data-node-id={@node_id}
      data-node-name={@name}
      data-drop-target-id={@node_id}
      data-drop-target-name={@name}
      data-accepted-types={@accepted_types}
      draggable="true"
      class="rounded"
    >
      <div
        data-layer-node-id={@node_id}
        class={[
          "group flex items-center gap-1 rounded transition hover:bg-base-200",
          @selected_id == @node_id && "bg-primary/10 text-primary"
        ]}
      >
        <button
          type="button"
          phx-click="select_element"
          phx-value-id={@node_id}
          phx-value-source="layers"
          class="min-w-0 flex-1 truncate px-2 py-1 text-left"
          style={"padding-left: #{@depth * 0.75 + 0.5}rem"}
        >
          {@name}
        </button>
        <button
          id={"page-builder-layer-duplicate-#{@node_id}"}
          type="button"
          phx-click="duplicate_node"
          phx-value-id={@node_id}
          class="btn btn-ghost btn-xs btn-circle shrink-0 text-base-content/50 opacity-0 transition hover:text-primary group-hover:opacity-100"
          aria-label={"Duplicate #{@name}"}
          title="Duplicate"
        >
          <.icon name="hero-document-duplicate" class="size-3.5" />
        </button>
        <button
          id={"page-builder-layer-delete-#{@node_id}"}
          type="button"
          phx-click="delete_node"
          phx-value-id={@node_id}
          class="btn btn-ghost btn-xs btn-circle shrink-0 text-base-content/50 opacity-0 transition hover:text-error group-hover:opacity-100"
          aria-label={"Delete #{@name}"}
          title="Delete"
        >
          <.icon name="hero-trash" class="size-3.5" />
        </button>
      </div>
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

  defp accepted_types(name), do: name |> EditorCanvas.accepted_child_types() |> Enum.join(",")

  attr(:selected_node, :map, default: nil)
  attr(:clipboard, :map, default: nil)
  attr(:uploads, :map, required: true)

  defp inspector(assigns) do
    props = safe_map(assigns.selected_node && Map.get(assigns.selected_node, "props"))
    classes = safe_map(assigns.selected_node && Map.get(assigns.selected_node, "classes"))
    name = node_value(assigns.selected_node, "name", "No selection")

    assigns =
      assigns
      |> assign(:node_id, node_value(assigns.selected_node, "id", ""))
      |> assign(:name, name)
      |> assign(:props, props)
      |> assign(:classes, classes)
      |> assign(:seo, safe_map(Map.get(props, "seo")))
      |> assign(:class_text, inspector_class_text(classes))
      |> assign(:class_tokens, class_tokens(inspector_class_text(classes)))
      |> assign(:class_suggestions, class_suggestions(name))

    ~H"""
    <div class="flex items-center justify-between border-b border-base-300 p-4">
      <div>
        <h2 class="font-semibold">{human_name(@name)}</h2>
        <p class="text-xs text-base-content/60">{@node_id}</p>
      </div>
      <div class="flex items-center gap-2">
        <button
          :if={@clipboard}
          id="builder-paste-node-button"
          type="button"
          phx-click="paste_node"
          class="btn btn-sm"
        >
          Paste
        </button>
        <button
          id="builder-close-inspector-button"
          type="button"
          phx-click="close_right_sidebar"
          class="btn btn-ghost btn-sm btn-circle"
          aria-label="Close properties"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>
    </div>

    <div :if={!@selected_node} class="p-4 text-sm text-base-content/60">
      Select a block to edit its properties.
    </div>

    <.form
      :if={@selected_node}
      for={to_form(%{}, as: :node)}
      id="builder-node-inspector-form"
      phx-change="update_selected_node"
      class="flex-1 space-y-5 overflow-y-auto p-4"
    >
      <div class="space-y-3">
        <h3 class="text-sm font-semibold">Properties</h3>
        <.prop_input
          :if={@name in ~w(heading paragraph blockquote button anchor)}
          label="Text"
          key_name="text"
          value={Map.get(@props, "text", "")}
        />
        <.prop_input
          :if={@name == "heading"}
          label="Level"
          key_name="level"
          value={Map.get(@props, "level", "2")}
        />
        <.prop_input
          :if={@name in ~w(button anchor image)}
          label="Href"
          key_name="href"
          value={Map.get(@props, "href", "")}
        />
        <.prop_input
          :if={@name in ~w(button anchor image)}
          label="Target"
          key_name="target"
          value={Map.get(@props, "target", "_self")}
        />
        <.prop_input
          :if={@name in ~w(image video)}
          label="Source URL"
          key_name="src"
          value={Map.get(@props, "src", "")}
        />
        <.prop_input
          :if={@name == "image"}
          label="Alt text"
          key_name="alt"
          value={Map.get(@props, "alt", "")}
        />
      </div>

      <div :if={@name == "image"} class="rounded-lg border border-base-300 p-3">
        <.live_file_input
          upload={@uploads.builder_asset}
          class="file-input file-input-bordered w-full"
        />
        <button type="button" phx-click="save_asset" class="btn btn-sm btn-primary mt-3">
          Use uploaded image
        </button>
      </div>

      <div class="space-y-3">
        <h3 class="text-sm font-semibold">SEO</h3>
        <.seo_input label="SEO title" key_name="title" value={Map.get(@seo, "title", "")} />
        <.seo_input
          label="SEO description"
          key_name="description"
          value={Map.get(@seo, "description", "")}
        />
        <.seo_input label="SEO keywords" key_name="keywords" value={Map.get(@seo, "keywords", "")} />
      </div>

      <div class="space-y-3">
        <h3 class="text-sm font-semibold">Styling</h3>
        <.class_tags tokens={@class_tokens} />
        <.class_suggestion_buttons suggestions={@class_suggestions} tokens={@class_tokens} />
        <.class_textarea
          label="Classes"
          key_name="display"
          value={@class_text}
          placeholder="btn btn-primary px-6 py-3"
        />
        <.class_textarea
          label="Custom CSS"
          key_name="custom_css"
          value={Map.get(@classes, "custom_css", "")}
          placeholder="border-radius: 1rem;"
        />
      </div>
    </.form>
    """
  end

  attr(:label, :string, required: true)
  attr(:key_name, :string, required: true)
  attr(:value, :string, default: "")

  defp prop_input(assigns) do
    ~H"""
    <.builder_input
      id={"builder-prop-#{@key_name}"}
      name={"node[props][#{@key_name}]"}
      label={@label}
      value={@value}
    />
    """
  end

  attr(:label, :string, required: true)
  attr(:key_name, :string, required: true)
  attr(:value, :string, default: "")

  defp seo_input(assigns) do
    ~H"""
    <.builder_input
      id={"builder-seo-#{@key_name}"}
      name={"node[props][seo][#{@key_name}]"}
      label={@label}
      value={@value}
    />
    """
  end

  attr(:tokens, :list, default: [])

  defp class_tags(assigns) do
    ~H"""
    <div
      :if={@tokens != []}
      class="flex flex-wrap gap-1.5 rounded-lg border border-base-300 bg-base-200/50 p-2"
    >
      <button
        :for={token <- @tokens}
        type="button"
        phx-click="remove_class"
        phx-value-class={token}
        class="badge badge-outline gap-1 font-mono"
      >
        {token}
        <.icon name="hero-x-mark" class="size-3" />
      </button>
    </div>
    """
  end

  attr(:suggestions, :list, default: [])
  attr(:tokens, :list, default: [])

  defp class_suggestion_buttons(assigns) do
    assigns =
      assign(
        assigns,
        :available_suggestions,
        Enum.reject(assigns.suggestions, &(&1 in assigns.tokens))
      )

    ~H"""
    <div :if={@available_suggestions != []} class="flex flex-wrap gap-1.5">
      <button
        :for={suggestion <- @available_suggestions}
        type="button"
        phx-click="add_class"
        phx-value-class={suggestion}
        class="btn btn-xs btn-ghost border border-base-300 font-mono"
      >
        + {suggestion}
      </button>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:key_name, :string, required: true)
  attr(:value, :string, default: "")
  attr(:placeholder, :string, default: "")

  defp class_textarea(assigns) do
    ~H"""
    <.builder_input
      id={"builder-style-#{@key_name}"}
      type="textarea"
      name={"node[classes][#{@key_name}]"}
      label={@label}
      value={@value}
      placeholder={@placeholder}
      input_class="textarea textarea-bordered min-h-20 resize-none overflow-hidden font-mono text-xs"
      phx_hook="AutoGrowTextArea"
      phx_debounce="300"
    />
    """
  end

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:label, :string, required: true)
  attr(:type, :string, default: "text")
  attr(:value, :any, default: "")
  attr(:placeholder, :string, default: "")
  attr(:input_class, :string, default: nil)
  attr(:phx_hook, :string, default: nil)
  attr(:phx_debounce, :string, default: nil)

  defp builder_input(assigns) do
    ~H"""
    <.input
      :if={@type == "textarea"}
      id={@id}
      type="textarea"
      name={@name}
      label={@label}
      value={@value}
      placeholder={@placeholder}
      class={@input_class || "w-full textarea"}
      phx-hook={@phx_hook}
      phx-debounce={@phx_debounce}
    />
    <.input
      :if={@type != "textarea"}
      id={@id}
      type={@type}
      name={@name}
      label={@label}
      value={@value}
      placeholder={@placeholder}
      class={@input_class || "w-full input"}
      phx-debounce={@phx_debounce}
    />
    """
  end

  attr(:versions, :list, default: [])
  attr(:tree, :list, default: [])
  attr(:manual_version_label, :string, default: "")

  defp version_history(assigns) do
    ~H"""
    <div class="border-b border-base-300 p-4">
      <div class="flex items-center justify-between gap-3">
        <h2 class="font-semibold">Version History</h2>
        <button
          id="builder-close-versions-button"
          type="button"
          phx-click="close_right_sidebar"
          class="btn btn-ghost btn-sm btn-circle"
          aria-label="Close versions"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>
      <.form
        for={to_form(%{"label" => @manual_version_label}, as: :version)}
        id="builder-save-version-form"
        phx-submit="save_manual_version"
        class="mt-3 flex gap-2"
      >
        <input
          name="version[label]"
          value={@manual_version_label}
          placeholder="Version label"
          class="input input-bordered input-sm min-w-0 flex-1"
        />
        <button class="btn btn-primary btn-sm">Save</button>
      </.form>
    </div>
    <div class="flex-1 overflow-y-auto p-4">
      <article
        :for={version <- @versions}
        id={"page-version-#{version.id}"}
        class="mb-3 rounded-lg border border-base-300 p-3"
        title={version_diff_title(@tree, version.content_tree)}
      >
        <div class="flex items-start justify-between gap-3">
          <div>
            <div class="font-semibold">Version {version.version_number}</div>
            <div class="text-xs text-base-content/60">{format_datetime(version.inserted_at)}</div>
          </div>
          <span class={version_badge_class(version.snapshot_type)}>
            {human_name(version.snapshot_type)}
          </span>
        </div>
        <p :if={version.label} class="mt-2 text-sm">{version.label}</p>
        <p :if={version.change_summary} class="mt-1 text-xs text-base-content/60">
          {version.change_summary}
        </p>
        <button
          id={"restore-page-version-#{version.id}"}
          type="button"
          phx-click="restore_version"
          phx-value-id={version.id}
          data-confirm="This will replace the current draft. Your current state will be saved first."
          class="btn btn-sm mt-3"
        >
          Restore
        </button>
      </article>
      <p :if={@versions == []} class="text-sm text-base-content/60">No versions yet.</p>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Mutation helpers
  # ---------------------------------------------------------------------------

  defp add_node_to_tree(socket, name, variant, target_id, position) do
    node = build_node(socket, name, variant)
    insert_valid_node(socket, node, target_id, position)
  end

  defp build_node(socket, "section_ref", section_id),
    do: new_node(socket, "section_ref", section_id)

  defp build_node(_socket, "loop", _variant), do: new_node(nil, "loop", nil)
  defp build_node(_socket, "anchor", variant), do: new_node(nil, "anchor", variant)
  defp build_node(_socket, "dynamic_form", variant), do: new_node(nil, "dynamic_form", variant)
  defp build_node(_socket, name, variant), do: Registry.default_node(name, variant)

  defp insert_valid_node(socket, node, target_id, position) do
    tree = socket.assigns.tree
    parent_name = target_container_name(tree, target_id, position)
    child_name = Map.get(node, "name")

    if target_id == "root" or EditorCanvas.accepts?(parent_name, child_name) do
      tree = ContentTree.insert_node(tree, target_id, node, position)

      socket
      |> mutate_tree(tree)
      |> assign(:selected_id, Map.get(node, "id"))
    else
      put_flash(
        socket,
        :error,
        "#{human_name(child_name)} cannot be added to #{human_name(parent_name)}"
      )
    end
  end

  defp mutate_tree(socket, tree) do
    tree = ContentTree.normalize_paths(tree)

    socket
    |> assign(:tree, tree)
    |> assign_history(tree)
  end

  defp update_selected_class_text(%{assigns: %{selected_id: nil}} = socket, _updater), do: socket

  defp update_selected_class_text(socket, updater) do
    selected_id = socket.assigns.selected_id
    node = selected_node(socket.assigns.tree, selected_id)
    class_text = node |> node_classes() |> inspector_class_text() |> updater.()

    tree =
      ContentTree.update_node_classes(socket.assigns.tree, selected_id, %{
        "display" => class_text,
        "daisy_ui" => "",
        "padding" => "",
        "margin" => "",
        "custom" => ""
      })

    mutate_tree(socket, tree)
  end

  defp normalize_inspector_classes(node_params) do
    classes = safe_map(Map.get(node_params, "classes"))

    if Map.has_key?(classes, "display") do
      classes
      |> Map.update("display", "", &normalize_class_text/1)
      |> Map.put("daisy_ui", "")
      |> Map.put("padding", "")
      |> Map.put("margin", "")
      |> Map.put("custom", "")
    else
      classes
    end
  end

  defp node_classes(%{"classes" => classes}) when is_map(classes), do: classes
  defp node_classes(_node), do: %{}

  defp inspector_class_text(classes) when is_map(classes) do
    ["display", "classes", "daisy_ui", "padding", "margin", "custom"]
    |> Enum.map(&Map.get(classes, &1, ""))
    |> Enum.join(" ")
    |> normalize_class_text()
  end

  defp inspector_class_text(_classes), do: ""

  defp normalize_class_text(value) when is_binary(value) do
    value
    |> String.split(~r/\s+/, trim: true)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  defp normalize_class_text(_value), do: ""

  defp class_tokens(value) when is_binary(value), do: String.split(value, ~r/\s+/, trim: true)
  defp class_tokens(_value), do: []

  defp add_class_token(value, token) do
    [value, token]
    |> Enum.join(" ")
    |> normalize_class_text()
  end

  defp remove_class_token(value, token) do
    value
    |> class_tokens()
    |> Enum.reject(&(&1 == token))
    |> Enum.join(" ")
  end

  defp assign_history(socket, tree) do
    history = socket.assigns[:history] || []
    index = socket.assigns[:history_index] || 0
    current = Enum.at(history, index)

    if current == tree do
      socket
    else
      next_history =
        history
        |> Enum.take(index + 1)
        |> Kernel.++([tree])
        |> Enum.take(-50)

      assign(socket, history: next_history, history_index: length(next_history) - 1)
    end
  end

  defp travel_history(socket, direction) do
    history = socket.assigns.history
    next_index = socket.assigns.history_index + direction

    if next_index in 0..(length(history) - 1) do
      tree = Enum.at(history, next_index)
      assign(socket, tree: tree, history_index: next_index, selected_id: first_node_id(tree))
    else
      socket
    end
  end

  defp assign_page_state(socket, %Page{} = page) do
    socket
    |> assign(:page, page)
    |> assign(:page_form, to_form(page_form_params(page), as: :page))
    |> assign(:current_version, page.content_tree_version || 1)
    |> reload_versions()
  end

  defp reload_versions(socket) do
    assign(
      socket,
      :versions,
      Pages.list_page_versions(socket.assigns.current_tenant, socket.assigns.page)
    )
  end

  defp noreply(socket), do: {:noreply, socket}

  # ---------------------------------------------------------------------------
  # Node presets
  # ---------------------------------------------------------------------------

  defp initial_tree(%Page{content_tree: tree}) when is_list(tree) and tree != [],
    do: ContentTree.normalize_paths(tree)

  defp initial_tree(_page), do: ContentTree.normalize_paths([section_node()])

  defp section_node do
    %{
      "type" => "component",
      "name" => "section",
      "id" => node_id("section"),
      "props" => %{},
      "classes" => %{"display" => "w-full bg-base-100 py-8"},
      "children" => [
        row_node("1:1")
      ]
    }
  end

  defp new_node(socket, "section_ref", section_id) do
    section = Enum.find(socket.assigns.sections, &(&1.id == section_id))

    %{
      "type" => "component",
      "name" => "section_ref",
      "id" => node_id("section-ref"),
      "props" => %{
        "section_id" => section_id,
        "name" => section && section.name,
        "template_linked" => true
      },
      "template_id" => section_id,
      "template_linked" => true,
      "classes" => %{"display" => ""},
      "children" => (section && section.content_tree) || []
    }
  end

  defp new_node(_socket, "loop", _variant) do
    %{
      "type" => "component",
      "name" => "loop",
      "id" => node_id("loop"),
      "props" => %{"source" => "", "as" => "item"},
      "classes" => %{},
      "children" => []
    }
  end

  defp new_node(_socket, "section", _variant), do: section_node()
  defp new_node(_socket, "row", variant), do: row_node(variant)
  defp new_node(_socket, "column", variant), do: column_node(column_class(variant))

  defp new_node(_socket, "heading", level) do
    leaf_node("heading", %{"text" => "New heading", "level" => level}, %{
      "display" => "text-3xl font-bold text-base-content"
    })
  end

  defp new_node(_socket, "paragraph", _variant) do
    leaf_node("paragraph", %{"text" => "Add your paragraph copy here."}, %{
      "display" => "text-base leading-7 text-base-content/75"
    })
  end

  defp new_node(_socket, "blockquote", _variant) do
    leaf_node("blockquote", %{"text" => "Add a customer quote or highlight."}, %{
      "display" => "border-l-4 border-primary pl-4 text-lg italic"
    })
  end

  defp new_node(_socket, "image", _variant) do
    leaf_node("image", %{"src" => ~p"/images/logo.svg", "alt" => ""}, %{
      "display" => "w-full rounded-lg object-cover"
    })
  end

  defp new_node(_socket, "video", _variant) do
    leaf_node("video", %{"src" => "", "title" => "Video"}, %{"display" => "aspect-video"})
  end

  defp new_node(_socket, "button", _variant) do
    leaf_node("button", %{"text" => "Get started", "href" => "/", "target" => "_self"}, %{
      "daisy_ui" => "btn btn-primary"
    })
  end

  defp new_node(_socket, "anchor", _variant) do
    leaf_node("anchor", %{"text" => "Learn more", "href" => "/", "target" => "_self"}, %{
      "daisy_ui" => "link link-primary"
    })
  end

  defp new_node(_socket, "dynamic_form", _variant) do
    leaf_node("dynamic_form", %{"label" => "Email", "submit_label" => "Submit"}, %{
      "display" => "card bg-base-100 p-4 shadow-sm"
    })
  end

  defp row_node(variant) do
    columns =
      variant
      |> ratio_columns()
      |> Enum.map(&column_node/1)

    %{
      "type" => "component",
      "name" => "row",
      "id" => node_id("row"),
      "props" => %{"gutter" => "default"},
      "classes" => %{
        "display" => "mx-auto grid w-full max-w-7xl grid-cols-12 gap-6 px-4 sm:px-6 lg:px-8"
      },
      "children" => columns
    }
  end

  defp column_node(class) do
    %{
      "type" => "component",
      "name" => "column",
      "id" => node_id("column"),
      "props" => %{},
      "classes" => %{"display" => class},
      "children" => [
        leaf_node("heading", %{"text" => "MangoCMS section", "level" => "2"}, %{
          "display" => "text-3xl font-bold text-base-content"
        }),
        leaf_node("paragraph", %{"text" => "Edit this copy directly on the canvas."}, %{
          "display" => "mt-4 text-base leading-7 text-base-content/75"
        })
      ]
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

  defp ratio_columns("2:1"), do: ["col-span-12 lg:col-span-8", "col-span-12 lg:col-span-4"]
  defp ratio_columns("3:1"), do: ["col-span-12 lg:col-span-9", "col-span-12 lg:col-span-3"]
  defp ratio_columns("4:1"), do: ["col-span-12 lg:col-span-10", "col-span-12 lg:col-span-2"]
  defp ratio_columns("3:2"), do: ["col-span-12 lg:col-span-7", "col-span-12 lg:col-span-5"]
  defp ratio_columns(_), do: ["col-span-12"]

  defp column_class("full"), do: "col-span-12"
  defp column_class(_variant), do: "col-span-12"

  defp node_id(prefix), do: "#{prefix}_#{Ecto.UUID.generate()}"

  # ---------------------------------------------------------------------------
  # View helpers
  # ---------------------------------------------------------------------------

  defp selected_node(_tree, nil), do: nil
  defp selected_node(tree, id), do: ContentTree.find_node(tree, id)

  defp first_node_id([%{"id" => id} | _rest]), do: id
  defp first_node_id(_tree), do: nil

  defp target_name(_tree, "root"), do: "root"

  defp target_name(tree, id) do
    case ContentTree.find_node(tree, id) do
      %{"name" => name} -> name
      _other -> "root"
    end
  end

  defp target_container_name(tree, target_id, :into), do: target_name(tree, target_id)
  defp target_container_name(_tree, "root", _position), do: "root"

  defp target_container_name(tree, target_id, _position) do
    with %{"path" => path} <- ContentTree.find_node(tree, target_id),
         parent_id when is_binary(parent_id) <- path |> String.split(".") |> List.last() do
      target_name(tree, parent_id)
    else
      _other -> "root"
    end
  end

  defp parse_position("before"), do: :before
  defp parse_position("after"), do: :after
  defp parse_position(_other), do: :into

  defp page_form_params(%Page{} = page) do
    %{
      "title" => page.title,
      "slug" => page.slug,
      "status" => page.status,
      "type" => page.type,
      "seo" => page.seo || %{}
    }
  end

  defp normalize_page_params(params, %Page{} = page) do
    seo =
      page.seo
      |> safe_map()
      |> Map.merge(safe_map(Map.get(params, "seo")))

    params
    |> Map.put_new("type", page.type)
    |> Map.put("seo", seo)
  end

  defp page_seo(%Page{seo: seo}, key), do: seo |> safe_map() |> Map.get(key, "")

  defp filtered_sections(sections, query) when query in [nil, ""], do: sections

  defp filtered_sections(sections, query) do
    query = query |> String.downcase() |> String.trim()

    Enum.filter(sections, fn section ->
      [section.name, section.group_label, section.mode]
      |> Enum.any?(fn value ->
        value
        |> to_string()
        |> String.downcase()
        |> String.contains?(query)
      end)
    end)
  end

  defp section_ref_groups(sections) do
    sections
    |> Enum.group_by(&section_group_label/1)
    |> Enum.sort_by(fn {group, _sections} -> String.downcase(group) end)
  end

  defp section_group_label(%{group_label: value}) when is_binary(value) do
    case String.trim(value) do
      "" -> "General"
      group -> group
    end
  end

  defp section_group_label(_section), do: "General"

  defp section_mode_label(%{mode: "dynamic"}), do: "Dynamic data"
  defp section_mode_label(%{mode: "reference"}), do: "Reference"
  defp section_mode_label(_section), do: "Static data"

  defp section_template_label(%{template_key: value}) when is_binary(value) do
    value
    |> String.replace(".", " / ")
    |> String.replace("_", " ")
  end

  defp section_template_label(_section), do: "custom"

  defp section_loop_label(%{
         settings: %{
           "section_type" => "slider",
           "items_visible" => visible,
           "interval_ms" => interval,
           "transition" => transition
         }
       }) do
    "Visible #{visible_count(visible, "desktop")}/#{visible_count(visible, "tablet")}/#{visible_count(visible, "mobile")} · #{seconds(interval)}s · #{transition}"
  end

  defp section_loop_label(%{loop_settings: %{"enabled" => true, "limit" => limit}}),
    do: "Loops #{limit || "records"} records"

  defp section_loop_label(%{loop_settings: %{enabled: true, limit: limit}}),
    do: "Loops #{limit || "records"} records"

  defp section_loop_label(_section), do: "No loop"

  defp visible_count(visible, key) when is_map(visible), do: Map.get(visible, key, "-")
  defp visible_count(_visible, _key), do: "-"

  defp seconds(interval) when is_integer(interval), do: div(interval, 1000)
  defp seconds(interval) when is_binary(interval), do: interval
  defp seconds(_interval), do: "-"

  defp section_mode_badge(%{mode: "dynamic"}), do: "badge badge-info shrink-0"
  defp section_mode_badge(%{mode: "reference"}), do: "badge badge-secondary shrink-0"
  defp section_mode_badge(_section), do: "badge badge-ghost shrink-0"

  defp class_suggestions("section") do
    ~w(w-full bg-base-100 bg-base-200 bg-primary text-primary-content py-8 py-12 px-4 rounded-xl shadow-sm)
  end

  defp class_suggestions("row") do
    ~w(mx-auto grid w-full max-w-7xl max-width-desktop grid-cols-12 gap-3 gap-4 gap-6 px-4 py-4)
  end

  defp class_suggestions("column") do
    ~w(col-span-12 md:col-span-6 lg:col-span-4 lg:col-span-6 lg:col-span-8 flex flex-col gap-4)
  end

  defp class_suggestions("heading") do
    ~w(text-2xl text-3xl text-4xl text-5xl font-bold font-extrabold text-base-content text-primary)
  end

  defp class_suggestions("paragraph") do
    ~w(text-sm text-base text-lg leading-7 text-base-content text-base-content/75 max-w-3xl)
  end

  defp class_suggestions("button") do
    ~w(btn btn-primary btn-secondary btn-outline btn-ghost btn-sm btn-md btn-lg rounded-full)
  end

  defp class_suggestions("anchor") do
    ~w(link link-primary link-hover text-primary font-semibold underline underline-offset-4)
  end

  defp class_suggestions("image") do
    ~w(w-full rounded-lg rounded-xl object-cover aspect-video shadow-md border border-base-300)
  end

  defp class_suggestions(_name) do
    ~w(w-full rounded-lg bg-base-100 text-base-content shadow-sm border border-base-300 p-4 m-0)
  end

  defp palette_groups do
    registry_groups =
      Registry.all()
      |> Enum.group_by(& &1.group)
      |> Enum.sort_by(fn {group, _} -> group end)
      |> Enum.map(fn {group_label, manifests} ->
        items =
          Enum.map(manifests, fn m ->
            %{name: m.name, label: m.label, icon: m.icon, variant: m.default_variant}
          end)

        %{id: String.downcase(group_label), label: group_label, items: items}
      end)

    legacy =
      if @legacy_palette_items == [],
        do: [],
        else: [%{id: "legacy", label: "Legacy", items: @legacy_palette_items}]

    registry_groups ++ legacy
  end

  defp filtered_palette(""), do: palette_groups()
  defp filtered_palette(nil), do: palette_groups()

  defp filtered_palette(query) do
    query = query |> String.downcase() |> String.trim()

    Enum.flat_map(palette_groups(), fn group ->
      items =
        Enum.filter(group.items, fn item ->
          String.contains?(String.downcase(item.label), query) or
            String.contains?(String.downcase(item.name), query)
        end)

      if items == [], do: [], else: [%{group | items: items}]
    end)
  end

  defp viewport_class("tablet"),
    do: "mx-auto min-h-[60vh] w-[768px] max-w-full bg-base-100 shadow-xl"

  defp viewport_class("mobile"),
    do: "mx-auto min-h-[60vh] w-[375px] max-w-full bg-base-100 shadow-xl"

  defp viewport_class(_desktop), do: "mx-auto min-h-[60vh] w-full bg-base-100 shadow-xl"

  defp node_value(nil, _key, fallback), do: fallback
  defp node_value(node, key, fallback), do: Map.get(node, key, fallback)

  defp safe_map(value) when is_map(value), do: value
  defp safe_map(_value), do: %{}

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value

  defp human_name(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_name(_value), do: "Block"

  defp deep_copy_with_new_ids(node) do
    node
    |> Map.put("id", node_id(Map.get(node, "name", "node")))
    |> Map.update("children", [], fn children ->
      Enum.map(children || [], &deep_copy_with_new_ids/1)
    end)
  end

  defp version_diff_title(tree, version_tree) do
    diff = ContentTree.diff_trees(version_tree || [], tree || [])

    "#{length(diff.added)} blocks added, #{length(diff.removed)} removed, #{length(diff.changed)} changed"
  end

  defp version_badge_class("publish_checkpoint"), do: "badge badge-success"
  defp version_badge_class("manual"), do: "badge badge-info"
  defp version_badge_class(_auto), do: "badge badge-ghost"

  defp format_datetime(nil), do: ""

  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
end
