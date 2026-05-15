defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.Cta do
  @moduledoc false

  use MangoCMSWeb, :html

  import MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  attr :section, :any, required: true

  def display(assigns) do
    ~H"""
    <div class={
      section_surface_class(@section, "rounded-lg border px-6 py-10 text-center", "bg-base-200")
    }>
      <p class={[
        "text-xs font-semibold uppercase tracking-wide text-primary",
        data_class_value(@section, "eyebrow")
      ]}>
        {text_or(data_value(@section, "eyebrow"), "CTA")}
      </p>
      <h3 class={[
        "mx-auto mt-3 max-w-2xl text-2xl font-bold text-base-content",
        data_class_value(@section, "title")
      ]}>
        {text_or(data_value(@section, "title"), "Ready to take the next step?")}
      </h3>
      <p class={[
        "mx-auto mt-3 max-w-2xl text-sm leading-6 text-base-content/70",
        data_class_value(@section, "subtitle")
      ]}>
        {text_or(data_value(@section, "subtitle"), "Add a focused call to action.")}
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
        {text_or(data_value(@section, "cta_label"), "Contact us")}
      </.link>
    </div>
    """
  end

  attr :section, :any, required: true
  attr :form, :any, required: true
  attr :width_options, :list, required: true

  def form(assigns) do
    ~H"""
    <div class={
      form_section_surface_class(
        @section,
        @form,
        "rounded-lg border px-6 py-10 text-center",
        "bg-base-200"
      )
    }>
      <.hidden_section_fields section={@section} type="cta" template_id="default" mode="fixed" />

      <div class="mx-auto max-w-xl text-left">
        <.editable_text
          id={"builder_cta_eyebrow_#{@section.id}"}
          name="section[fixed_data][eyebrow]"
          label="CTA eyebrow"
          value={fixed_value(@form, "eyebrow")}
          placeholder="Next step"
          class={[
            "text-center text-xs font-semibold uppercase tracking-wide text-primary",
            fixed_class_value(@form, "eyebrow")
          ]}
          data-builder-element="text"
          data-builder-field="eyebrow"
        />

        <.editable_text
          id={"builder_cta_title_#{@section.id}"}
          name="section[fixed_data][title]"
          label="CTA title"
          value={fixed_value(@form, "title")}
          placeholder="Ready to take the next step?"
          class={[
            "mt-3 text-center text-2xl font-bold text-base-content",
            fixed_class_value(@form, "title")
          ]}
          data-builder-element="text"
          data-builder-field="title"
        />
        <.editable_text
          id={"builder_cta_subtitle_#{@section.id}"}
          name="section[fixed_data][subtitle]"
          label="CTA subtitle"
          value={fixed_value(@form, "subtitle")}
          placeholder="Short supporting copy."
          multiline
          class={[
            "mt-3 text-center text-base leading-7 text-base-content/70",
            fixed_class_value(@form, "subtitle")
          ]}
          data-builder-element="text"
          data-builder-field="subtitle"
        />

        <input
          id={"builder_cta_label_#{@section.id}"}
          name="section[fixed_data][cta_label]"
          value={fixed_value(@form, "cta_label")}
          type="hidden"
        />
        <button
          type="button"
          class={[
            "btn btn-primary btn-sm mx-auto mt-3 inline-flex min-w-32 justify-center ring-1 ring-primary/30 transition hover:ring-primary/70",
            fixed_value(@form, "cta_text_class"),
            fixed_value(@form, "cta_classes")
          ]}
          data-builder-element="link"
          data-builder-field="cta_label"
        >
          {text_or(fixed_value(@form, "cta_label"), "Contact us")}
        </button>
      </div>
    </div>
    """
  end
end
