defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.Cta do
  @moduledoc false

  use MangoCMSWeb, :html

  import MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  attr :section, :any, required: true

  def display(assigns) do
    ~H"""
    <div class="rounded-lg bg-base-200 px-6 py-10 text-center">
      <p class="text-xs font-semibold uppercase tracking-wide text-primary">
        {text_or(data_value(@section, "eyebrow"), "CTA")}
      </p>
      <h3 class="mx-auto mt-3 max-w-2xl text-2xl font-bold text-base-content">
        {text_or(data_value(@section, "title"), "Ready to take the next step?")}
      </h3>
      <p class="mx-auto mt-3 max-w-2xl text-sm leading-6 text-base-content/70">
        {text_or(data_value(@section, "subtitle"), "Add a focused call to action.")}
      </p>
      <span class="btn btn-primary btn-sm mt-5">
        {text_or(data_value(@section, "cta_label"), "Contact us")}
      </span>
    </div>
    """
  end

  attr :section, :any, required: true
  attr :form, :any, required: true
  attr :width_options, :list, required: true

  def form(assigns) do
    ~H"""
    <div class="rounded-lg bg-base-200 px-6 py-10 text-center">
      <.hidden_section_fields section={@section} type="cta" template_id="default" mode="fixed" />

      <div class="mx-auto max-w-xl text-left">
        <.editable_text
          id={"builder_cta_eyebrow_#{@section.id}"}
          name="section[fixed_data][eyebrow]"
          label="CTA eyebrow"
          value={fixed_value(@form, "eyebrow")}
          placeholder="Next step"
          class="text-center text-xs font-semibold uppercase tracking-wide text-primary"
        />

        <.editable_text
          id={"builder_cta_title_#{@section.id}"}
          name="section[fixed_data][title]"
          label="CTA title"
          value={fixed_value(@form, "title")}
          placeholder="Ready to take the next step?"
          class="mt-3 text-center text-2xl font-bold text-base-content"
        />
        <.editable_text
          id={"builder_cta_subtitle_#{@section.id}"}
          name="section[fixed_data][subtitle]"
          label="CTA subtitle"
          value={fixed_value(@form, "subtitle")}
          placeholder="Short supporting copy."
          multiline
          class="mt-3 text-center text-base leading-7 text-base-content/70"
        />

        <div class="grid gap-3 sm:grid-cols-2">
          <.editable_text
            id={"builder_cta_label_#{@section.id}"}
            name="section[fixed_data][cta_label]"
            label="Button label"
            value={fixed_value(@form, "cta_label")}
            placeholder="Contact us"
            class="btn btn-primary btn-sm mx-auto mt-3 inline-flex min-w-32 justify-center"
          />
          <.input
            id={"builder_cta_href_#{@section.id}"}
            name="section[fixed_data][cta_href]"
            type="text"
            label="Button href"
            value={fixed_value(@form, "cta_href")}
            placeholder="/contact"
            class="w-full input"
          />
        </div>
      </div>
    </div>
    """
  end
end
