defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.Text do
  @moduledoc false

  use MangoCMSWeb, :html

  import MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  attr :section, :any, required: true

  def display(assigns) do
    ~H"""
    <div class="rounded-lg bg-base-100 p-6">
      <p class="text-xs font-semibold uppercase tracking-wide text-primary">
        {text_or(data_value(@section, "eyebrow"), "Text")}
      </p>
      <h3 class="mt-3 text-2xl font-bold text-base-content">
        {text_or(data_value(@section, "title"), "Untitled text section")}
      </h3>
      <p class="mt-4 whitespace-pre-line text-sm leading-6 text-base-content/70">
        {text_or(data_value(@section, "body"), data_value(@section, "subtitle") || "Add body copy.")}
      </p>
    </div>
    """
  end

  attr :section, :any, required: true
  attr :form, :any, required: true
  attr :width_options, :list, required: true

  def form(assigns) do
    ~H"""
    <div class="rounded-lg bg-base-100 p-6">
      <.hidden_section_fields section={@section} type="text" template_id="default" mode="fixed" />

      <.editable_text
        id={"builder_text_eyebrow_#{@section.id}"}
        name="section[fixed_data][eyebrow]"
        label="Text eyebrow"
        value={fixed_value(@form, "eyebrow")}
        placeholder="Overview"
        class="text-xs font-semibold uppercase tracking-wide text-primary"
      />

      <.editable_text
        id={"builder_text_title_#{@section.id}"}
        name="section[fixed_data][title]"
        label="Heading"
        value={fixed_value(@form, "title")}
        placeholder="Section heading"
        class="mt-3 text-2xl font-bold text-base-content"
      />
      <.editable_text
        id={"builder_text_body_#{@section.id}"}
        name="section[fixed_data][body]"
        label="Body"
        value={fixed_value(@form, "body")}
        placeholder="Write the section body directly here."
        multiline
        class="mt-4 min-h-32 whitespace-pre-line text-base leading-7 text-base-content/70"
      />
    </div>
    """
  end
end
