defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.DynamicGrid do
  @moduledoc false

  use MangoCMSWeb, :html

  import MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  attr :section, :any, required: true

  def display(assigns) do
    ~H"""
    <div class="rounded-lg bg-base-100 p-5">
      <p class="text-xs font-semibold uppercase tracking-wide text-primary">
        {text_or(data_value(@section, "eyebrow"), "Dynamic")}
      </p>
      <h3 class="mt-3 text-2xl font-bold text-base-content">
        {text_or(data_value(@section, "title"), "Dynamic content grid")}
      </h3>
      <p class="mt-2 text-sm leading-6 text-base-content/70">
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
    <div class="rounded-lg bg-base-100 p-5">
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
        class="text-xs font-semibold uppercase tracking-wide text-primary"
      />

      <.editable_text
        id={"builder_dynamic_title_#{@section.id}"}
        name="section[fixed_data][title]"
        label="Grid title"
        value={fixed_value(@form, "title")}
        placeholder="Featured content"
        class="mt-3 text-2xl font-bold text-base-content"
      />
      <.editable_text
        id={"builder_dynamic_subtitle_#{@section.id}"}
        name="section[fixed_data][subtitle]"
        label="Grid subtitle"
        value={fixed_value(@form, "subtitle")}
        placeholder="Short supporting copy."
        multiline
        class="mt-2 text-base leading-7 text-base-content/70"
      />

      <div class="mt-5 rounded-lg border border-base-300 bg-base-200 p-4">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h4 class="font-semibold text-base-content">Dynamic source</h4>
            <p class="text-sm text-base-content/60">
              Choose the content pool this section reads from.
            </p>
          </div>
          <span class="rounded-full bg-base-100 px-2.5 py-1 text-xs font-semibold text-base-content/70">
            Dynamic
          </span>
        </div>

        <div class="mt-4 grid gap-4 md:grid-cols-4">
          <.input
            id={"builder_dynamic_source_content_type_#{@section.id}"}
            name="section[source][content_type_id]"
            type="select"
            label="Content type"
            options={@content_type_options}
            value={source_value(@source_params, "content_type_id")}
            class="w-full select"
          />
          <.input
            id={"builder_dynamic_source_status_#{@section.id}"}
            name="section[source][status]"
            type="select"
            label="Status"
            options={@source_status_options}
            value={source_value(@source_params, "status")}
            class="w-full select"
          />
          <.input
            id={"builder_dynamic_source_limit_#{@section.id}"}
            name="section[source][limit]"
            type="number"
            label="Limit"
            min="1"
            max="50"
            value={source_value(@source_params, "limit")}
            class="w-full input"
          />
          <.input
            id={"builder_dynamic_source_offset_#{@section.id}"}
            name="section[source][offset]"
            type="number"
            label="Offset"
            min="0"
            value={source_value(@source_params, "offset")}
            class="w-full input"
          />
        </div>

        <div class="mt-4 grid gap-4 md:grid-cols-3">
          <.input
            id={"builder_dynamic_filter_field_#{@section.id}"}
            name="section[source][filters][field]"
            type="text"
            label="Filter field"
            value={source_filter_value(@source_params, "field")}
            placeholder="rating"
            class="w-full input"
          />
          <.input
            id={"builder_dynamic_filter_op_#{@section.id}"}
            name="section[source][filters][op]"
            type="select"
            label="Operator"
            options={@operator_options}
            value={source_filter_value(@source_params, "op")}
            class="w-full select"
          />
          <.input
            id={"builder_dynamic_filter_value_#{@section.id}"}
            name="section[source][filters][value]"
            type="text"
            label="Filter value"
            value={source_filter_value(@source_params, "value")}
            placeholder="5"
            class="w-full input"
          />
        </div>

        <div class="mt-4 grid gap-4 md:grid-cols-2">
          <.input
            id={"builder_dynamic_sort_field_#{@section.id}"}
            name="section[source][sort][field]"
            type="text"
            label="Sort field"
            value={source_sort_value(@source_params, "field")}
            placeholder="published_at"
            class="w-full input"
          />
          <.input
            id={"builder_dynamic_sort_direction_#{@section.id}"}
            name="section[source][sort][direction]"
            type="select"
            label="Sort direction"
            options={[{"Descending", "desc"}, {"Ascending", "asc"}]}
            value={source_sort_value(@source_params, "direction")}
            class="w-full select"
          />
        </div>
      </div>

      <div class="mt-5 grid gap-3 md:grid-cols-3">
        <div
          :for={{mapping, index} <- Enum.with_index(@mapping_rows)}
          class="rounded-lg border border-base-300 bg-base-100 p-3"
        >
          <input
            type="hidden"
            name={"section[mappings][#{index}][slot]"}
            value={mapping["slot"]}
          />
          <input
            type="hidden"
            name={"section[mappings][#{index}][position]"}
            value={mapping["position"]}
          />
          <p class="text-xs font-semibold uppercase tracking-wide text-base-content/50">
            {mapping_label(mapping["slot"])}
          </p>
          <.input
            id={"builder_dynamic_mapping_#{@section.id}_#{mapping["slot"]}_source"}
            name={"section[mappings][#{index}][source_path]"}
            type="text"
            label="Path"
            value={mapping["source_path"]}
            placeholder="payload.name"
            class="w-full input input-sm"
          />
          <.input
            id={"builder_dynamic_mapping_#{@section.id}_#{mapping["slot"]}_formatter"}
            name={"section[mappings][#{index}][formatter]"}
            type="select"
            label="Formatter"
            options={@formatter_options}
            value={mapping["formatter"]}
            class="w-full select select-sm"
          />
        </div>
      </div>
    </div>
    """
  end
end
