defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.Hero do
  @moduledoc false

  use MangoCMSWeb, :html

  import MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  attr :section, :any, required: true

  def display(assigns) do
    ~H"""
    <div class="rounded-lg bg-base-100 p-5">
      <div class="grid gap-6 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wide text-primary">
            {text_or(data_value(@section, "eyebrow"), "Hero")}
          </p>
          <h3 class="mt-3 text-3xl font-bold leading-tight text-base-content">
            {text_or(data_value(@section, "title"), "Untitled hero")}
          </h3>
          <p class="mt-3 max-w-2xl text-sm leading-6 text-base-content/70">
            {text_or(data_value(@section, "subtitle"), "Add short supporting copy.")}
          </p>
          <span class="btn btn-primary btn-sm mt-5">
            {text_or(data_value(@section, "cta_label"), "Call to action")}
          </span>
        </div>

        <div class="aspect-video rounded-lg border border-dashed border-base-300 bg-base-200 p-5">
          <div class="grid h-full place-items-center rounded-md bg-base-100 text-sm text-base-content/50">
            {text_or(data_value(@section, "image_url"), "Hero image")}
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :section, :any, required: true
  attr :form, :any, required: true
  attr :width_options, :list, required: true

  def form(assigns) do
    ~H"""
    <div class="rounded-lg bg-base-100 p-5">
      <.hidden_section_fields section={@section} type="hero" template_id="default" mode="fixed" />

      <div class="grid gap-6 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
        <div>
          <div class="grid gap-3 md:grid-cols-[1fr_auto] md:items-end">
            <.input
              id={"builder_hero_eyebrow_#{@section.id}"}
              name="section[fixed_data][eyebrow]"
              type="text"
              label="Eyebrow"
              value={fixed_value(@form, "eyebrow")}
              placeholder="Featured"
              class="w-full input input-sm"
            />
            <.input
              id={"builder_hero_width_#{@section.id}"}
              name="section[settings][width]"
              type="select"
              label="Width"
              options={@width_options}
              value={settings_value(@form, "width", "full")}
              class="w-full select select-sm"
            />
          </div>

          <.input
            id={"builder_hero_title_#{@section.id}"}
            name="section[fixed_data][title]"
            type="text"
            label="Hero title"
            value={fixed_value(@form, "title")}
            placeholder="A clear headline for this page"
            class="w-full input input-ghost h-auto px-0 py-2 text-3xl font-bold leading-tight sm:text-4xl"
          />

          <.input
            id={"builder_hero_subtitle_#{@section.id}"}
            name="section[fixed_data][subtitle]"
            type="textarea"
            label="Hero subtitle"
            value={fixed_value(@form, "subtitle")}
            rows="3"
            placeholder="Short supporting copy."
            class="w-full textarea textarea-ghost px-0 text-base leading-7"
          />

          <div class="grid gap-3 sm:grid-cols-2">
            <.input
              id={"builder_hero_cta_label_#{@section.id}"}
              name="section[fixed_data][cta_label]"
              type="text"
              label="Button label"
              value={fixed_value(@form, "cta_label")}
              placeholder="Get started"
              class="w-full input"
            />
            <.input
              id={"builder_hero_cta_href_#{@section.id}"}
              name="section[fixed_data][cta_href]"
              type="text"
              label="Button href"
              value={fixed_value(@form, "cta_href")}
              placeholder="/contact"
              class="w-full input"
            />
          </div>
        </div>

        <div class="rounded-lg border border-base-300 bg-base-200 p-4">
          <.input
            id={"builder_hero_image_url_#{@section.id}"}
            name="section[fixed_data][image_url]"
            type="url"
            label="Hero image URL"
            value={fixed_value(@form, "image_url")}
            placeholder="/images/logo.png"
            class="w-full input"
          />
          <div class="mt-3 aspect-video rounded-md bg-base-100 p-4 text-sm text-base-content/50">
            Image preview area
          </div>
        </div>
      </div>
    </div>
    """
  end
end
