defmodule MangoCMSWeb.PageRenderer do
  @moduledoc """
  Recursive renderer for MangoCMS content-tree AST nodes.

  Public pages call this renderer without admin markup. The editor canvas wraps
  the same renderer with `MangoCMSWeb.Live.Admin.EditorCanvas` overlays.
  """

  use MangoCMSWeb, :html

  alias MangoCMSWeb.PageElements

  attr :tree, :list, default: []

  @doc "Renders a full content tree recursively."
  @spec render_tree(map()) :: Phoenix.LiveView.Rendered.t()
  def render_tree(assigns) do
    ~H"""
    <%= for node <- @tree do %>
      <.render_node node={node} />
    <% end %>
    """
  end

  attr :node, :map, required: true

  @doc "Renders one content-tree node and all of its children."
  @spec render_node(map()) :: Phoenix.LiveView.Rendered.t()
  def render_node(assigns) do
    assigns =
      assigns
      |> assign(:name, Map.get(assigns.node, "name", "unknown"))
      |> assign(:props, safe_map(Map.get(assigns.node, "props")))
      |> assign(:classes, safe_map(Map.get(assigns.node, "classes")))
      |> assign(:children, safe_children(assigns.node))

    ~H"""
    <%= case @name do %>
      <% "section" -> %>
        <PageElements.section props={@props} classes={@classes}>
          <.render_tree tree={@children} />
        </PageElements.section>
      <% "row" -> %>
        <PageElements.row props={@props} classes={@classes}>
          <.render_tree tree={@children} />
        </PageElements.row>
      <% "column" -> %>
        <PageElements.column props={@props} classes={@classes}>
          <.render_tree tree={@children} />
        </PageElements.column>
      <% "heading" -> %>
        <PageElements.heading props={@props} classes={@classes} />
      <% "paragraph" -> %>
        <PageElements.paragraph props={@props} classes={@classes} />
      <% "blockquote" -> %>
        <PageElements.blockquote props={@props} classes={@classes} />
      <% "image" -> %>
        <PageElements.image props={@props} classes={@classes} />
      <% "video" -> %>
        <PageElements.video props={@props} classes={@classes} />
      <% "button" -> %>
        <PageElements.button props={@props} classes={@classes} />
      <% "anchor" -> %>
        <PageElements.anchor props={@props} classes={@classes} />
      <% "dynamic_form" -> %>
        <PageElements.dynamic_form props={@props} classes={@classes} />
      <% "section_ref" -> %>
        <.render_tree tree={@children} />
      <% "loop" -> %>
        <.render_tree tree={@children} />
      <% _other -> %>
        <PageElements.unknown props={@props} classes={@classes}>
          <.render_tree tree={@children} />
        </PageElements.unknown>
    <% end %>
    """
  end

  @doc "Returns true when a content tree contains at least one node."
  @spec tree_present?(term()) :: boolean()
  def tree_present?(tree), do: is_list(tree) and tree != []

  @doc "Returns safe children for a node."
  @spec safe_children(map()) :: list()
  def safe_children(node) when is_map(node) do
    case Map.get(node, "children") do
      children when is_list(children) -> children
      _other -> []
    end
  end

  def safe_children(_node), do: []

  defp safe_map(value) when is_map(value), do: value
  defp safe_map(_value), do: %{}
end
