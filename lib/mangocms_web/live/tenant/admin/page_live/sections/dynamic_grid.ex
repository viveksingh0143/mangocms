defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.DynamicGrid do
  @moduledoc false

  use MangoCMSWeb, :html

  import MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  attr :section, :any, required: true

  def display(assigns) do
    ~H"""
    <div class={section_surface_class(@section, "rounded-lg border p-5")}>
      <p class={[
        "text-xs font-semibold uppercase tracking-wide text-primary",
        data_class_value(@section, "eyebrow")
      ]}>
        {text_or(data_value(@section, "eyebrow"), "Dynamic")}
      </p>
      <h3 class={["mt-3 text-2xl font-bold text-base-content", data_class_value(@section, "title")]}>
        {text_or(data_value(@section, "title"), "Dynamic content grid")}
      </h3>
      <p class={[
        "mt-2 text-sm leading-6 text-base-content/70",
        data_class_value(@section, "subtitle")
      ]}>
        {text_or(data_value(@section, "subtitle"), "Cards are rendered from tenant content entries.")}
      </p>

      <div class="mt-5 grid gap-3 md:grid-cols-3">
        <div :for={index <- 1..3} class="rounded-lg border border-base-300 bg-base-100 p-4">
          <div class="mb-3 h-20 rounded-md bg-base-200"></div>
          <p class="text-xs font-semibold text-primary">Mapped item {index}</p>
          <p class="mt-2 font-semibold text-base-content">Entry title</p>
          <p class="mt-1 text-sm text-base-content/60">Mapped subtitle or excerpt.</p>
        </div>
      </div>
    </div>
    """
  end

  attr :section, :any, required: true
  attr :form, :any, required: true
  attr :width_options, :list, required: true
  attr :source_params, :map, required: true
  attr :mapping_rows, :list, required: true
  attr :content_type_options, :list, required: true
  attr :source_status_options, :list, required: true
  attr :operator_options, :list, required: true
  attr :formatter_options, :list, required: true

  def form(assigns) do
    ~H"""
    <div class={form_section_surface_class(@section, @form, "rounded-lg border p-5")}>
      <.hidden_section_fields
        section={@section}
        type="feature_grid"
        template_id="cards"
        mode="dynamic"
      />

      <.editable_text
        id={"builder_dynamic_eyebrow_#{@section.id}"}
        name="section[fixed_data][eyebrow]"
        label="Dynamic eyebrow"
        value={fixed_value(@form, "eyebrow")}
        placeholder="Dynamic"
        class={[
          "text-xs font-semibold uppercase tracking-wide text-primary",
          fixed_class_value(@form, "eyebrow")
        ]}
        data-builder-element="text"
        data-builder-field="eyebrow"
      />

      <.editable_text
        id={"builder_dynamic_title_#{@section.id}"}
        name="section[fixed_data][title]"
        label="Grid title"
        value={fixed_value(@form, "title")}
        placeholder="Featured content"
        class={["mt-3 text-2xl font-bold text-base-content", fixed_class_value(@form, "title")]}
        data-builder-element="text"
        data-builder-field="title"
      />
      <.editable_text
        id={"builder_dynamic_subtitle_#{@section.id}"}
        name="section[fixed_data][subtitle]"
        label="Grid subtitle"
        value={fixed_value(@form, "subtitle")}
        placeholder="Short supporting copy."
        multiline
        class={[
          "mt-2 text-base leading-7 text-base-content/70",
          fixed_class_value(@form, "subtitle")
        ]}
        data-builder-element="text"
        data-builder-field="subtitle"
      />
    </div>
    """
  end
end
