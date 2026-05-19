defmodule MangoCMSWeb.Builder.Renderer do
  @moduledoc """
  Manifest-aware renderer for the new builder library components.

  This renderer is intentionally separate from the existing page renderer. It
  proves that manifest-backed components can render in public or builder
  contexts without coupling to the current page/section builder internals.
  """

  use MangoCMSWeb, :html

  alias MangoCMSWeb.Builder.Registry

  attr :node, :map, required: true
  attr :context, :map, default: %{}

  @doc "Renders a node through its manifest renderer."
  @spec node(map()) :: Phoenix.LiveView.Rendered.t()
  def node(assigns) do
    manifest = Registry.get!(assigns.node["name"])
    {module, function} = manifest.renderer

    apply(module, function, [assigns])
  end
end
