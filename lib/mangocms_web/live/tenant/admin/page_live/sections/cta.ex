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
        <div class="grid gap-3 md:grid-cols-[1fr_auto] md:items-end">
          <.input
            id={"builder_cta_eyebrow_#{@section.id}"}
            name="section[fixed_data][eyebrow]"
            type="text"
            label="Eyebrow"
            value={fixed_value(@form, "eyebrow")}
            placeholder="Next step"
            class="w-full input input-sm"
          />
          <.input
            id={"builder_cta_width_#{@section.id}"}
            name="section[settings][width]"
            type="select"
            label="Width"
            options={@width_options}
            value={settings_value(@form, "width", "full")}
            class="w-full select select-sm"
          />
        </div>

        <.input
          id={"builder_cta_title_#{@section.id}"}
          name="section[fixed_data][title]"
          type="text"
          label="CTA title"
          value={fixed_value(@form, "title")}
          placeholder="Ready to take the next step?"
          class="w-full input input-ghost h-auto px-0 py-2 text-center text-2xl font-bold"
        />
        <.input
          id={"builder_cta_subtitle_#{@section.id}"}
          name="section[fixed_data][subtitle]"
          type="textarea"
          label="CTA subtitle"
          value={fixed_value(@form, "subtitle")}
          rows="3"
          placeholder="Short supporting copy."
          class="w-full textarea textarea-ghost px-0 text-center text-base leading-7"
        />

        <div class="grid gap-3 sm:grid-cols-2">
          <.input
            id={"builder_cta_label_#{@section.id}"}
            name="section[fixed_data][cta_label]"
            type="text"
            label="Button label"
            value={fixed_value(@form, "cta_label")}
            placeholder="Contact us"
            class="w-full input"
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
