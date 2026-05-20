defmodule MangoCMSWeb.Live.Admin.EditorCanvas do
  @moduledoc """
  Admin-only wrapper around page content-tree presentation components.

  The wrapper injects editor affordances such as outlines, handles, selection
  click targets, and drop-zone metadata while leaving `PageElements` pure.
  """

  use MangoCMSWeb, :html

  alias MangoCMSWeb.Builder.Registry
  alias MangoCMSWeb.Builder.Renderer
  alias MangoCMSWeb.PageRenderer
  alias MangoCMSWeb.PageElements

  @accepted_types %{
    "root" => ["section", "container", "section_ref"],
    "section" => ["container", "row", "column", "grid", "heading", "paragraph", "image", "button"],
    "container" => [
      "row",
      "column",
      "grid",
      "heading",
      "paragraph",
      "image",
      "button",
      "rich_text"
    ],
    "row" => ["column"],
    "column" => [
      "heading",
      "paragraph",
      "rich_text",
      "blockquote",
      "code_block",
      "ordered_list",
      "unordered_list",
      "text_gradient",
      "label_text",
      "image",
      "video",
      "audio",
      "gallery",
      "embed",
      "icon_block",
      "feature_card",
      "cta_section",
      "testimonial",
      "pricing_card",
      "team_member",
      "faq_section",
      "banner",
      "logo_grid",
      "steps_section",
      "empty_state",
      "notification_bar",
      "copy_button",
      "read_more",
      "scroll_to_top",
      "cookie_banner",
      "back_link",
      "share_buttons",
      "table_of_contents",
      "button",
      "anchor",
      "dynamic_form",
      "loop",
      "section_ref"
    ],
    "grid" => ["column", "feature_card", "card", "image", "heading"],
    "loop" => [
      "heading",
      "paragraph",
      "blockquote",
      "image",
      "video",
      "button",
      "anchor",
      "column"
    ],
    "section_ref" => []
  }

  attr :tree, :list, default: []
  attr :selected_id, :string, default: nil

  @doc "Renders the editable canvas tree with root drop metadata."
  @spec canvas(map()) :: Phoenix.LiveView.Rendered.t()
  def canvas(assigns) do
    ~H"""
    <div
      id="editor-canvas-root"
      data-drop-target-id="root"
      data-drop-target-name="root"
      data-accepted-types={accepted_types("root")}
      class="min-h-[48vh]"
    >
      <%= for node <- @tree do %>
        <.editable_node node={node} selected_id={@selected_id} />
      <% end %>
      <div
        :if={@tree == []}
        class="rounded-xl border border-dashed border-base-300 bg-base-100 p-12 text-center text-base-content/60"
      >
        Drag a section here or add one from the palette.
      </div>
    </div>
    """
  end

  attr :node, :map, required: true
  attr :selected_id, :string, default: nil

  @doc "Renders one editable node with admin overlays and recursive children."
  @spec editable_node(map()) :: Phoenix.LiveView.Rendered.t()
  def editable_node(assigns) do
    assigns =
      assigns
      |> assign(:node_id, Map.get(assigns.node, "id", ""))
      |> assign(:name, Map.get(assigns.node, "name", "unknown"))
      |> assign(:children, PageRenderer.safe_children(assigns.node))

    ~H"""
    <div
      id={"canvas-node-#{@node_id}"}
      data-node-id={@node_id}
      data-node-name={@name}
      data-drop-target-id={@node_id}
      data-drop-target-name={@name}
      data-accepted-types={accepted_types(@name)}
      draggable="true"
      phx-click="select_element"
      phx-value-id={@node_id}
      phx-value-source="canvas"
      class={[
        "group relative rounded-md border border-transparent transition hover:border-dashed hover:border-primary/60 hover:bg-primary/5",
        canvas_wrapper_class(@node),
        @selected_id == @node_id && "border-primary bg-primary/10",
        empty_container?(@node, @children) && "min-h-12 border-dashed border-base-300"
      ]}
    >
      <div class="pointer-events-none absolute top-2 left-2 z-10 rounded-md bg-base-100/90 px-2 py-1 text-[11px] font-semibold uppercase tracking-wide text-base-content/60 shadow-sm opacity-0 transition group-hover:opacity-100">
        {@name}
      </div>
      <div class="absolute top-2 right-2 z-10 flex gap-1 opacity-0 transition group-hover:opacity-100">
        <button
          type="button"
          class="btn btn-xs btn-circle"
          title="Copy"
          phx-click="copy_node"
          phx-value-id={@node_id}
        >
          <.icon name="hero-clipboard-document" class="size-3" />
        </button>
        <button
          type="button"
          class="btn btn-xs btn-circle text-error"
          title="Delete"
          phx-click="delete_node"
          phx-value-id={@node_id}
          data-confirm="Delete this block?"
        >
          <.icon name="hero-trash" class="size-3" />
        </button>
      </div>

      <div class={if(empty_container?(@node, @children), do: "p-2", else: "p-0")}>
        <.editable_node_body
          node={@node}
          name={@name}
          children={@children}
          selected_id={@selected_id}
        />
      </div>
    </div>
    """
  end

  attr :node, :map, required: true
  attr :name, :string, required: true
  attr :children, :list, default: []
  attr :selected_id, :string, default: nil

  @doc "Renders the presentation body for an editable node."
  @spec editable_node_body(map()) :: Phoenix.LiveView.Rendered.t()
  def editable_node_body(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <%= case @name do %>
      <%!-- Legacy container nodes (PageElements-backed) --%>
      <% "section" -> %>
        <PageElements.section props={@props} classes={@classes}>
          <%= for child <- @children do %>
            <.editable_node node={child} selected_id={@selected_id} />
          <% end %>
        </PageElements.section>
      <% "row" -> %>
        <PageElements.row props={@props} classes={@classes}>
          <%= for child <- @children do %>
            <.editable_node node={child} selected_id={@selected_id} />
          <% end %>
        </PageElements.row>
      <% "column" -> %>
        <PageElements.column props={@props} classes={@classes}>
          <%= for child <- @children do %>
            <.editable_node node={child} selected_id={@selected_id} />
          <% end %>
        </PageElements.column>
      <% "section_ref" -> %>
        <%= for child <- @children do %>
          <.editable_node node={child} selected_id={@selected_id} />
        <% end %>
      <% "loop" -> %>
        <div class={PageElements.class_names(@classes, "grid gap-4 md:grid-cols-3")}>
          <%= for child <- @children do %>
            <.editable_node node={child} selected_id={@selected_id} />
          <% end %>
        </div>
        <%!-- Manifest container nodes (LayoutComponents-backed) --%>
      <% "container" -> %>
        <div class={[
          "mx-auto w-full",
          Map.get(@props, "padding_x", ""),
          Map.get(@props, "padding_y", ""),
          Map.get(@classes, "custom", "")
        ]}>
          <%= for child <- @children do %>
            <.editable_node node={child} selected_id={@selected_id} />
          <% end %>
        </div>
      <% "grid" -> %>
        <div class={["grid gap-6", Map.get(@classes, "custom", "")]}>
          <%= for child <- @children do %>
            <.editable_node node={child} selected_id={@selected_id} />
          <% end %>
        </div>
        <%!-- Legacy editable-text nodes --%>
      <% "heading" -> %>
        <.editable_text_node node={@node} tag="heading" classes={@classes} />
      <% "paragraph" -> %>
        <.editable_text_node node={@node} tag="paragraph" classes={@classes} />
      <% "blockquote" -> %>
        <.editable_text_node node={@node} tag="blockquote" classes={@classes} />
      <% "button" -> %>
        <.editable_text_node node={@node} tag="button" classes={@classes} />
      <% "anchor" -> %>
        <.editable_text_node node={@node} tag="anchor" classes={@classes} />
        <%!-- Manifest leaf nodes via Registry --%>
      <% _other -> %>
        <%= if Registry.get(@name) do %>
          <Renderer.node node={@node} context={%{mode: :editor}} />
        <% else %>
          <PageRenderer.render_node node={@node} />
        <% end %>
    <% end %>
    """
  end

  attr :node, :map, required: true
  attr :tag, :string, required: true
  attr :classes, :map, default: %{}

  @doc "Renders text-bearing nodes with the contenteditable LiveView bridge."
  @spec editable_text_node(map()) :: Phoenix.LiveView.Rendered.t()
  def editable_text_node(assigns) do
    assigns =
      assigns
      |> assign(:node_id, Map.get(assigns.node, "id", ""))
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:text, get_in(assigns.node, ["props", "text"]) || "")

    ~H"""
    <div
      id={"editable-text-#{@node_id}"}
      phx-hook="AstContentEditable"
      phx-update="ignore"
      contenteditable="true"
      data-node-id={@node_id}
      data-property="text"
      x-data="{ toolbar: false }"
      x-on:focus="toolbar = true"
      x-on:blur="toolbar = false"
      class={[
        "rounded outline-none transition focus:ring-2 focus:ring-primary/40",
        text_node_class(@tag, @classes)
      ]}
      style={PageElements.style_attr(@classes)}
    >{@text}</div>
    """
  end

  @doc "Returns accepted child component names for a container node."
  @spec accepted_child_types(String.t()) :: [String.t()]
  def accepted_child_types(name) when is_binary(name) do
    case Map.get(@accepted_types, name) do
      nil ->
        case Registry.get(name) do
          %{accepted_children: children} when children != [] -> children
          _ -> []
        end

      types ->
        types
    end
  end

  @doc "Checks whether a child component may be dropped into a container."
  @spec accepts?(String.t(), String.t()) :: boolean()
  def accepts?(parent_name, child_name) when is_binary(parent_name) and is_binary(child_name) do
    child_name in accepted_child_types(parent_name)
  end

  defp accepted_types(name), do: name |> accepted_child_types() |> Enum.join(",")

  defp text_node_class("button", classes),
    do: PageElements.class_names(classes, "btn btn-primary")

  defp text_node_class("anchor", classes),
    do: PageElements.class_names(classes, "link link-primary")

  defp text_node_class("heading", classes),
    do: PageElements.class_names(classes, "text-3xl font-bold")

  defp text_node_class("paragraph", classes),
    do: PageElements.class_names(classes, "text-base leading-7")

  defp text_node_class("blockquote", classes),
    do: PageElements.class_names(classes, "border-l-4 pl-4 italic")

  defp text_node_class(_tag, classes), do: PageElements.class_names(classes, "")

  defp empty_container?(%{"name" => name}, []),
    do: name in ["section", "container", "row", "column", "grid", "loop"]

  defp empty_container?(_node, _children), do: false

  defp canvas_wrapper_class(%{"name" => "column", "classes" => classes}) when is_map(classes) do
    PageElements.class_names(classes, "col-span-12")
  end

  defp canvas_wrapper_class(_node), do: nil
end
