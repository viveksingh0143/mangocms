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
     |> assign(:settings_json, encode_json(section.settings || %{}))
     |> assign(:source_config_json, encode_json(section.source_config || %{}))
     |> assign(:filters_json, encode_json(section.filters || %{}))
     |> assign(:loop_settings_json, encode_json(section.loop_settings || %{}))}
  end

  @impl true
  def handle_event("select_element", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_id, id)}
  end

  def handle_event("add_node", %{"name" => name}, socket) do
    tree = ContentTree.insert_node(socket.assigns.tree, "root", new_node(name), :into)
    {:noreply, assign(socket, :tree, tree)}
  end

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
      </:actions>

      <section id="section-builder" class="grid min-h-[72vh] gap-4 lg:grid-cols-[16rem_1fr_22rem]">
        <aside class="rounded-lg border border-base-300 bg-base-100 p-4">
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
        </aside>

        <main class="overflow-auto rounded-lg border border-base-300 bg-base-200 p-4">
          <div class="mx-auto max-w-5xl rounded-lg bg-base-100 p-4 shadow-sm">
            <EditorCanvas.canvas tree={@tree} selected_id={@selected_id} />
          </div>
        </main>

        <aside class="rounded-lg border border-base-300 bg-base-100 p-4">
          <.form for={to_form(%{}, as: :section)} id="section-builder-form" phx-submit="save_section">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
              Data source
            </h2>
            <p class="mt-2 text-xs text-base-content/60">
              Set <code>kind</code>
              to <code>content_type</code>
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

  defp block_palette do
    [
      %{name: "section", label: "Section", icon: "hero-square-3-stack-3d"},
      %{name: "row", label: "Row", icon: "hero-bars-3"},
      %{name: "column", label: "Column", icon: "hero-rectangle-group"},
      %{name: "heading", label: "Heading", icon: "hero-h1"},
      %{name: "paragraph", label: "Paragraph", icon: "hero-document-text"},
      %{name: "image", label: "Image", icon: "hero-photo"},
      %{name: "button", label: "Button", icon: "hero-cursor-arrow-rays"}
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
end
