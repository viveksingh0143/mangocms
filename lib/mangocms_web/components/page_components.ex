defmodule MangoCMSWeb.PageComponents do
  @moduledoc """
  Small public page helpers kept for controller template imports.

  The current renderer uses `MangoCMSWeb.PageRenderer` and `pages.content_tree`.
  """

  use MangoCMSWeb, :html

  attr :page, :map, required: true
  attr :sections, :list, default: []
  attr :section_items, :map, default: %{}

  @doc "Legacy-compatible fallback for pages without a content tree."
  def tenant_page(assigns) do
    ~H"""
    <main id="tenant-page-fallback" class="bg-base-100 text-base-content">
      <section class="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <h1 class="text-4xl font-bold tracking-tight">{@page.title}</h1>
      </section>
    </main>
    """
  end
end
