defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.Hero do
  @moduledoc false

  use MangoCMSWeb, :html

  import MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  attr :section, :any, required: true

  def display(assigns) do
    ~H"""
    <div class={section_surface_class(@section, "rounded-lg border p-5")}>
      <div class={["grid gap-6 lg:items-center", hero_ratio_class(@section)]}>
        <div>
          <p class={[
            "text-xs font-semibold uppercase tracking-wide text-primary",
            data_class_value(@section, "eyebrow")
          ]}>
            {text_or(data_value(@section, "eyebrow"), "Hero")}
          </p>
          <h3 class={[
            "mt-3 text-3xl font-bold leading-tight text-base-content",
            data_class_value(@section, "title")
          ]}>
            {text_or(data_value(@section, "title"), "Untitled hero")}
          </h3>
          <p class={[
            "mt-3 max-w-2xl text-sm leading-6 text-base-content/70",
            data_class_value(@section, "subtitle")
          ]}>
            {text_or(data_value(@section, "subtitle"), "Add short supporting copy.")}
          </p>
          <.link
            href={text_or(data_value(@section, "cta_href"), "#")}
            target={link_target(data_value(@section, "cta_target"))}
            title={data_value(@section, "cta_title")}
            class={[
              "btn btn-primary btn-sm mt-5",
              data_value(@section, "cta_text_class"),
              data_value(@section, "cta_classes")
            ]}
          >
            {text_or(data_value(@section, "cta_label"), "Call to action")}
          </.link>
        </div>

        <div class="aspect-video rounded-lg border border-dashed border-base-300 bg-base-200 p-5">
          <div class="grid h-full place-items-center rounded-md bg-base-100 text-sm text-base-content/50">
            <img
              :if={data_value(@section, "image_url")}
              src={data_value(@section, "image_url")}
              alt={data_value(@section, "image_alt") || ""}
              class={["h-full w-full rounded-md object-cover", data_value(@section, "image_classes")]}
            />
            <span :if={!data_value(@section, "image_url")}>Hero image</span>
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
    <div class={form_section_surface_class(@section, @form, "rounded-lg border p-5")}>
      <.hidden_section_fields section={@section} type="hero" template_id="default" mode="fixed" />

      <div class={["grid gap-6 lg:items-center", form_hero_ratio_class(@section, @form)]}>
        <div>
          <.editable_text
            id={"builder_hero_eyebrow_#{@section.id}"}
            name="section[fixed_data][eyebrow]"
            label="Hero eyebrow"
            value={fixed_value(@form, "eyebrow")}
            placeholder="Featured"
            class={[
              "mb-3 text-xs font-semibold uppercase tracking-wide text-primary",
              fixed_class_value(@form, "eyebrow")
            ]}
            data-builder-element="text"
            data-builder-field="eyebrow"
          />

          <.editable_text
            id={"builder_hero_title_#{@section.id}"}
            name="section[fixed_data][title]"
            label="Hero title"
            value={fixed_value(@form, "title")}
            placeholder="A clear headline for this page"
            class={[
              "text-3xl font-bold leading-tight text-base-content sm:text-4xl",
              fixed_class_value(@form, "title")
            ]}
            data-builder-element="text"
            data-builder-field="title"
          />

          <.editable_text
            id={"builder_hero_subtitle_#{@section.id}"}
            name="section[fixed_data][subtitle]"
            label="Hero subtitle"
            value={fixed_value(@form, "subtitle")}
            placeholder="Short supporting copy."
            multiline
            class={[
              "mt-4 max-w-2xl text-base leading-7 text-base-content/70",
              fixed_class_value(@form, "subtitle")
            ]}
            data-builder-element="text"
            data-builder-field="subtitle"
          />

          <input
            id={"builder_hero_cta_label_#{@section.id}"}
            name="section[fixed_data][cta_label]"
            value={fixed_value(@form, "cta_label")}
            type="hidden"
          />
          <button
            type="button"
            class={[
              "btn btn-primary btn-sm mt-3 inline-flex min-w-32 justify-center ring-1 ring-primary/30 transition hover:ring-primary/70",
              fixed_value(@form, "cta_text_class"),
              fixed_value(@form, "cta_classes")
            ]}
            data-builder-element="link"
            data-builder-field="cta_label"
          >
            {text_or(fixed_value(@form, "cta_label"), "Get started")}
          </button>
        </div>

        <div
          class="aspect-video rounded-lg border border-dashed border-base-300 bg-base-200 p-5"
          data-builder-element="image"
        >
          <div class="grid h-full place-items-center rounded-md bg-base-100 text-sm text-base-content/50">
            <img
              :if={fixed_value(@form, "image_url")}
              src={fixed_value(@form, "image_url")}
              alt={fixed_value(@form, "image_alt") || ""}
              class={[
                "h-full w-full rounded-md object-cover",
                fixed_value(@form, "image_classes")
              ]}
            />
            <span :if={!fixed_value(@form, "image_url")}>Hero image</span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
