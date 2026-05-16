defmodule MangoCMSWeb.Live.Admin.EditorCanvas do
  @moduledoc """
  Admin-only wrapper around page content-tree presentation components.

  The wrapper injects editor affordances such as outlines, handles, selection
  click targets, and drop-zone metadata while leaving `PageElements` pure.
  """

  use MangoCMSWeb, :html

  alias MangoCMSWeb.PageRenderer
  alias MangoCMSWeb.PageElements

  @accepted_types %{
    "root" => ["section", "section_ref"],
    "section" => ["row"],
    "row" => ["column"],
    "column" => [
      "heading",
      "paragraph",
      "blockquote",
      "image",
      "video",
      "button",
      "anchor",
      "dynamic_form",
      "section_ref"
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
        "group relative my-1 rounded-md border border-dashed border-base-300 transition hover:border-primary/60 hover:bg-primary/5",
        canvas_wrapper_class(@node),
        @selected_id == @node_id && "border-primary bg-primary/10"
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

      <div class="p-2">
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
      <% _other -> %>
        <PageRenderer.render_node node={@node} />
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
  def accepted_child_types(name) when is_binary(name), do: Map.get(@accepted_types, name, [])

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

  defp canvas_wrapper_class(%{"name" => "column", "classes" => classes}) when is_map(classes) do
    PageElements.class_names(classes, "col-span-12")
  end

  defp canvas_wrapper_class(_node), do: nil
end
