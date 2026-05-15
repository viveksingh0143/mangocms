defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.Text do
  @moduledoc false

  use MangoCMSWeb, :html

  import MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  attr :section, :any, required: true

  def display(assigns) do
    ~H"""
    <div class={section_surface_class(@section, "rounded-lg border p-6")}>
      <p class={[
        "text-xs font-semibold uppercase tracking-wide text-primary",
        data_class_value(@section, "eyebrow")
      ]}>
        {text_or(data_value(@section, "eyebrow"), "Text")}
      </p>
      <h3
        :if={data_value(@section, "title")}
        class={["mt-3 text-2xl font-bold text-base-content", data_class_value(@section, "title")]}
      >
        {data_value(@section, "title")}
      </h3>
      <p
        :if={data_value(@section, "body") || data_value(@section, "subtitle")}
        class={[
          "mt-4 whitespace-pre-line text-sm leading-6 text-base-content/70",
          data_class_value(@section, "body")
        ]}
      >
        {data_value(@section, "body") || data_value(@section, "subtitle")}
      </p>
    </div>
    """
  end

  attr :section, :any, required: true
  attr :form, :any, required: true
  attr :width_options, :list, required: true

  def form(assigns) do
    ~H"""
    <div class={form_section_surface_class(@section, @form, "rounded-lg border p-6")}>
      <.hidden_section_fields section={@section} type="text" template_id="default" mode="fixed" />

      <.editable_text
        id={"builder_text_eyebrow_#{@section.id}"}
        name="section[fixed_data][eyebrow]"
        label="Text eyebrow"
        value={fixed_value(@form, "eyebrow")}
        placeholder="Overview"
        class={[
          "text-xs font-semibold uppercase tracking-wide text-primary",
          fixed_class_value(@form, "eyebrow")
        ]}
        data-builder-element="text"
        data-builder-field="eyebrow"
      />

      <.editable_text
        id={"builder_text_title_#{@section.id}"}
        name="section[fixed_data][title]"
        label="Heading"
        value={fixed_value(@form, "title")}
        placeholder="Section heading"
        class={["mt-3 text-2xl font-bold text-base-content", fixed_class_value(@form, "title")]}
        data-builder-element="text"
        data-builder-field="title"
      />
      <.editable_text
        id={"builder_text_body_#{@section.id}"}
        name="section[fixed_data][body]"
        label="Body"
        value={fixed_value(@form, "body")}
        placeholder="Write the section body directly here."
        multiline
        class={[
          "mt-4 min-h-32 whitespace-pre-line text-base leading-7 text-base-content/70",
          fixed_class_value(@form, "body")
        ]}
        data-builder-element="text"
        data-builder-field="body"
      />
    </div>
    """
  end
end
