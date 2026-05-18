defmodule MangoCMSWeb.Tenant.Admin.SectionLive.Builder do
  use MangoCMSWeb, :live_view

  alias MangoCMS.ContentTree
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

    {:noreply,
     socket
     |> assign(:section, section)
     |> assign(:tree, tree)
     |> assign(:selected_id, nil)
     |> assign(:left_tab, "components")
     |> assign(:right_sidebar_open?, true)
     |> assign(:right_sidebar_size, "normal")
     |> assign(:settings_json, encode_json(section.settings || %{}))
     |> assign(:source_config_json, encode_json(section.source_config || %{}))
     |> assign(:filters_json, encode_json(section.filters || %{}))
     |> assign(:loop_settings_json, encode_json(section.loop_settings || %{}))}
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
    {:noreply, assign(socket, :tree, tree)}
  end

  def handle_event("delete_node", %{"id" => id}, socket) do
    socket =
      socket
      |> assign(:tree, ContentTree.delete_node(socket.assigns.tree, id))
      |> maybe_clear_selection(id)

    {:noreply, socket}
  end

  def handle_event("copy_node", _params, socket), do: {:noreply, socket}

  def handle_event("delete_selected", _params, %{assigns: %{selected_id: id}} = socket)
      when is_binary(id) do
    {:noreply, assign(socket, :tree, ContentTree.delete_node(socket.assigns.tree, id))}
  end

  def handle_event("delete_selected", _params, socket), do: {:noreply, socket}

  def handle_event("update_selected", %{"node" => params}, socket) do
    selected_id = socket.assigns.selected_id

    tree =
      socket.assigns.tree
      |> ContentTree.update_node_props(selected_id, %{
        "text" => params["text"],
        "href" => params["href"],
        "src" => params["src"],
        "alt" => params["alt"]
      })
      |> ContentTree.update_node_classes(selected_id, %{"custom" => params["classes"] || ""})

    {:noreply, assign(socket, :tree, tree)}
  end

  def handle_event("save_section", %{"section" => params}, socket) do
    attrs = %{
      "settings" => decode_map(params["settings_json"]),
      "source_config" => decode_map(params["source_config_json"]),
      "filters" => decode_map(params["filters_json"]),
      "loop_settings" => decode_map(params["loop_settings_json"]),
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
          <div class="mx-auto max-w-5xl rounded-lg bg-base-100 p-4 shadow-sm">
            <EditorCanvas.canvas tree={@tree} selected_id={@selected_id} />
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
            for={to_form(%{}, as: :section)}
            id="section-builder-form"
            phx-submit="save_section"
            class="min-h-0 flex-1 overflow-y-auto p-4"
          >
            <div class="rounded-lg border border-base-300 p-4">
              <h3 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
                Section properties
              </h3>
              <p class="mt-2 text-xs text-base-content/60">
                Set <code>kind</code>
                to <code>collection</code>
                or <code>product</code>. Dynamic
                elements can use placeholders like <code phx-no-curly-interpolation>{{title}}</code>
                and <code phx-no-curly-interpolation>{{price}}</code>.
              </p>
              <.input
                id="section-builder-source-config"
                name="section[source_config_json]"
                type="textarea"
                label="Source config JSON"
                value={@source_config_json}
                rows="5"
              />
              <.input
                id="section-builder-filters"
                name="section[filters_json]"
                type="textarea"
                label="Filters JSON"
                value={@filters_json}
                rows="4"
              />
              <.input
                id="section-builder-loop"
                name="section[loop_settings_json]"
                type="textarea"
                label="Loop settings JSON"
                value={@loop_settings_json}
                rows="4"
              />
              <.input
                id="section-builder-settings"
                name="section[settings_json]"
                type="textarea"
                label="Settings JSON"
                value={@settings_json}
                rows="4"
              />
            </div>

            <div class="mt-4 border-t border-base-300 pt-4">
              <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
                Selected element
              </h2>
              <%= if selected = selected_node(@tree, @selected_id) do %>
                <.selected_node_form node={selected} />
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
              <.button id="section-builder-save-button" variant="primary" phx-disable-with="Saving...">
                Save
              </.button>
            </div>
          </.form>
        </aside>
      </section>
    </Layouts.tenant_admin>
    """
  end

  attr :node, :map, required: true

  defp selected_node_form(assigns) do
    props = Map.get(assigns.node, "props", %{})
    classes = Map.get(assigns.node, "classes", %{})

    assigns =
      assigns
      |> assign(:props, props)
      |> assign(:classes, classes)

    ~H"""
    <div id={"section-builder-selected-#{@node["id"]}"} class="mt-3 grid gap-3">
      <.input
        id="section-builder-selected-text"
        name="node[text]"
        type="textarea"
        label="Text"
        value={@props["text"] || ""}
        rows="3"
        phx-change="update_selected"
      />
      <.input
        id="section-builder-selected-href"
        name="node[href]"
        type="text"
        label="Link"
        value={@props["href"] || ""}
        phx-change="update_selected"
      />
      <.input
        id="section-builder-selected-src"
        name="node[src]"
        type="text"
        label="Image/video URL"
        value={@props["src"] || ""}
        phx-change="update_selected"
      />
      <.input
        id="section-builder-selected-alt"
        name="node[alt]"
        type="text"
        label="Alt text"
        value={@props["alt"] || ""}
        phx-change="update_selected"
      />
      <.input
        id="section-builder-selected-classes"
        name="node[classes]"
        type="textarea"
        label="Classes"
        value={@classes["custom"] || ""}
        rows="3"
        phx-change="update_selected"
      />
    </div>
    """
  end

  defp selected_node(tree, id) when is_binary(id), do: ContentTree.find_node(tree, id)
  defp selected_node(_tree, _id), do: nil

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

  defp decode_map(value) do
    case Jason.decode(value || "") do
      {:ok, decoded} when is_map(decoded) -> decoded
      _other -> %{}
    end
  end

  defp encode_json(value), do: Jason.encode!(value, pretty: true)

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
  defp sidebar_subtitle("maximized"), do: "Section and element inspector"
  defp sidebar_subtitle(_size), do: "Section and selected element"

  defp maybe_clear_selection(socket, id) do
    if socket.assigns.selected_id == id do
      assign(socket, :selected_id, nil)
    else
      socket
    end
  end
end
