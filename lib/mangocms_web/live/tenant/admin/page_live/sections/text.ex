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

      <div class="grid gap-3 md:grid-cols-[1fr_auto] md:items-end">
        <.input
          id={"builder_text_eyebrow_#{@section.id}"}
          name="section[fixed_data][eyebrow]"
          type="text"
          label="Eyebrow"
          value={fixed_value(@form, "eyebrow")}
          placeholder="Overview"
          class="w-full input input-sm"
        />
        <.input
          id={"builder_text_width_#{@section.id}"}
          name="section[settings][width]"
          type="select"
          label="Width"
          options={@width_options}
          value={settings_value(@form, "width", "narrow")}
          class="w-full select select-sm"
        />
      </div>

      <.input
        id={"builder_text_title_#{@section.id}"}
        name="section[fixed_data][title]"
        type="text"
        label="Heading"
        value={fixed_value(@form, "title")}
        placeholder="Section heading"
        class="w-full input input-ghost h-auto px-0 py-2 text-2xl font-bold"
      />
      <.input
        id={"builder_text_body_#{@section.id}"}
        name="section[fixed_data][body]"
        type="textarea"
        label="Body"
        value={fixed_value(@form, "body")}
        rows="6"
        placeholder="Write the section body directly here."
        class="w-full textarea textarea-ghost min-h-40 px-0 text-base leading-7"
      />
    </div>
    """
  end
end
