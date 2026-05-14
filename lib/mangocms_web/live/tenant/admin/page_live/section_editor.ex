defmodule MangoCMSWeb.Tenant.Admin.PageLive.SectionEditor do
  @moduledoc "Dispatches tenant page-builder section previews and inline forms."

  use MangoCMSWeb, :html

  alias MangoCMS.Tenant.Pages.PageSection
  alias MangoCMSWeb.Tenant.Admin.PageLive.Sections.{Cta, DynamicGrid, Hero, Text}

  attr :section, PageSection, required: true

  def preview(%{section: %PageSection{mode: "dynamic"}} = assigns),
    do: DynamicGrid.display(assigns)

  def preview(%{section: %PageSection{type: "hero"}} = assigns), do: Hero.display(assigns)
  def preview(%{section: %PageSection{type: "cta"}} = assigns), do: Cta.display(assigns)
  def preview(%{section: %PageSection{type: "text"}} = assigns), do: Text.display(assigns)
  def preview(assigns), do: Text.display(assigns)

  attr :section, PageSection, required: true
  attr :form, :any, required: true
  attr :width_options, :list, required: true
  attr :source_params, :map, default: %{}
  attr :mapping_rows, :list, default: []
  attr :content_type_options, :list, default: []
  attr :source_status_options, :list, default: []
  attr :operator_options, :list, default: []
  attr :formatter_options, :list, default: []

  def form(%{section: %PageSection{mode: "dynamic"}} = assigns), do: DynamicGrid.form(assigns)
  def form(%{section: %PageSection{type: "hero"}} = assigns), do: Hero.form(assigns)
  def form(%{section: %PageSection{type: "cta"}} = assigns), do: Cta.form(assigns)
  def form(%{section: %PageSection{type: "text"}} = assigns), do: Text.form(assigns)
  def form(assigns), do: Text.form(assigns)
end
