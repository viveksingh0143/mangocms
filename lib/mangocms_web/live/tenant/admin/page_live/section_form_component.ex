defmodule MangoCMSWeb.Tenant.Admin.PageLive.SectionFormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.Pages
  alias MangoCMS.Tenant.Pages.{PageSection, SectionMapping, SectionSource}

  @type_options PageSection.type_options()
  @mode_options [{"Fixed", "fixed"}, {"Dynamic", "dynamic"}]
  @source_status_options SectionSource.status_options()
  @operator_options SectionSource.operator_options()
  @formatter_options SectionMapping.formatter_options()

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>
          Fixed sections render directly. Dynamic sections pull tenant content entries through a source query and slot mappings.
        </:subtitle>
      </.header>

      <.form
        for={@form}
        id="page-section-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid gap-5 md:grid-cols-4">
          <.input field={@form[:type]} type="select" label="Section type" options={@type_options} />
          <.input field={@form[:template_id]} type="text" label="Template" placeholder="default" />
          <.input field={@form[:mode]} type="select" label="Mode" options={@mode_options} />
          <.input field={@form[:position]} type="number" label="Position" min="0" />
        </div>

        <div class="rounded-lg border border-base-300 bg-base-200 p-4">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h3 class="font-semibold text-base-content">Fixed content</h3>
              <p class="text-sm text-base-content/60">
                These values render when mode is fixed.
              </p>
            </div>
            <span class="rounded-full bg-base-100 px-2.5 py-1 text-xs font-semibold text-base-content/70">
              fixed_data
            </span>
          </div>

          <div class="mt-4 grid gap-5 md:grid-cols-2">
            <.input
              id="page_section_fixed_data_eyebrow"
              name="page_section[fixed_data][eyebrow]"
              type="text"
              label="Eyebrow"
              value={fixed_value(@form, "eyebrow")}
              placeholder="Featured"
            />
            <.input
              id="page_section_fixed_data_title"
              name="page_section[fixed_data][title]"
              type="text"
              label="Title"
              value={fixed_value(@form, "title")}
              placeholder="Build your website with MangoCMS"
            />
            <.input
              id="page_section_fixed_data_subtitle"
              name="page_section[fixed_data][subtitle]"
              type="textarea"
              label="Subtitle"
              value={fixed_value(@form, "subtitle")}
              rows="3"
              placeholder="Short supporting copy."
            />
            <.input
              id="page_section_fixed_data_body"
              name="page_section[fixed_data][body]"
              type="textarea"
              label="Body"
              value={fixed_value(@form, "body")}
              rows="3"
              placeholder="Longer section copy."
            />
            <.input
              id="page_section_fixed_data_cta_label"
              name="page_section[fixed_data][cta_label]"
              type="text"
              label="CTA label"
              value={fixed_value(@form, "cta_label")}
              placeholder="Get started"
            />
            <.input
              id="page_section_fixed_data_cta_href"
              name="page_section[fixed_data][cta_href]"
              type="text"
              label="CTA href"
              value={fixed_value(@form, "cta_href")}
              placeholder="/contact"
            />
            <.input
              id="page_section_fixed_data_image_url"
              name="page_section[fixed_data][image_url]"
              type="url"
              label="Image URL"
              value={fixed_value(@form, "image_url")}
              placeholder="/images/example.jpg"
            />
          </div>
        </div>

        <div
          :if={dynamic_mode?(@form)}
          id="page-section-source-panel"
          class="rounded-lg border border-base-300 bg-base-200 p-4"
        >
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h3 class="font-semibold text-base-content">Source query</h3>
              <p class="text-sm text-base-content/60">
                Select a content type, optional indexed filter, sort order, and result limit.
              </p>
            </div>
            <span class="rounded-full bg-base-100 px-2.5 py-1 text-xs font-semibold text-base-content/70">
              section_source
            </span>
          </div>

          <p :if={@source_error} class="mt-4 rounded-lg bg-error/10 p-3 text-sm text-error">
            {@source_error}
          </p>

          <div class="mt-4 grid gap-5 md:grid-cols-4">
            <.input
              id="page_section_source_content_type_id"
              name="page_section[source][content_type_id]"
              type="select"
              label="Content type"
              options={@content_type_options}
              value={source_value(@source_params, "content_type_id")}
            />
            <.input
              id="page_section_source_status"
              name="page_section[source][status]"
              type="select"
              label="Entry status"
              options={@source_status_options}
              value={source_value(@source_params, "status")}
            />
            <.input
              id="page_section_source_limit"
              name="page_section[source][limit]"
              type="number"
              label="Limit"
              min="1"
              max="50"
              value={source_value(@source_params, "limit")}
            />
            <.input
              id="page_section_source_offset"
              name="page_section[source][offset]"
              type="number"
              label="Offset"
              min="0"
              value={source_value(@source_params, "offset")}
            />
          </div>

          <div class="mt-5 grid gap-5 md:grid-cols-3">
            <.input
              id="page_section_source_filter_field"
              name="page_section[source][filters][field]"
              type="text"
              label="Filter field"
              value={source_filter_value(@source_params, "field")}
              placeholder="rating"
            />
            <.input
              id="page_section_source_filter_op"
              name="page_section[source][filters][op]"
              type="select"
              label="Operator"
              options={@operator_options}
              value={source_filter_value(@source_params, "op")}
            />
            <.input
              id="page_section_source_filter_value"
              name="page_section[source][filters][value]"
              type="text"
              label="Filter value"
              value={source_filter_value(@source_params, "value")}
              placeholder="5"
            />
          </div>

          <div class="mt-5 grid gap-5 md:grid-cols-2">
            <.input
              id="page_section_source_sort_field"
              name="page_section[source][sort][field]"
              type="text"
              label="Sort field"
              value={source_sort_value(@source_params, "field")}
              placeholder="published_at"
            />
            <.input
              id="page_section_source_sort_direction"
              name="page_section[source][sort][direction]"
              type="select"
              label="Sort direction"
              options={[{"Descending", "desc"}, {"Ascending", "asc"}]}
              value={source_sort_value(@source_params, "direction")}
            />
          </div>

          <div class="mt-6 overflow-hidden rounded-lg border border-base-300 bg-base-100">
            <div class="border-b border-base-300 p-4">
              <h4 class="font-semibold text-base-content">Slot mappings</h4>
              <p class="mt-1 text-sm text-base-content/60">
                Map UI slots to entry paths such as title, slug, payload.name, or payload.price.
              </p>
            </div>

            <div class="divide-y divide-base-300">
              <div
                :for={{mapping, index} <- Enum.with_index(@mapping_rows)}
                id={"page-section-mapping-#{mapping["slot"]}"}
                class="grid gap-4 p-4 md:grid-cols-[0.7fr_1.3fr_1fr] md:items-center"
              >
                <input
                  type="hidden"
                  name={"page_section[mappings][#{index}][slot]"}
                  value={mapping["slot"]}
                />
                <input
                  type="hidden"
                  name={"page_section[mappings][#{index}][position]"}
                  value={mapping["position"]}
                />

                <div>
                  <p class="font-medium text-base-content">{mapping_label(mapping["slot"])}</p>
                  <p class="text-xs text-base-content/60">{mapping["slot"]}</p>
                </div>

                <.input
                  id={"page_section_mapping_#{mapping["slot"]}_source_path"}
                  name={"page_section[mappings][#{index}][source_path]"}
                  type="text"
                  label="Source path"
                  value={mapping["source_path"]}
                  placeholder="payload.name"
                />

                <.input
                  id={"page_section_mapping_#{mapping["slot"]}_formatter"}
                  name={"page_section[mappings][#{index}][formatter]"}
                  type="select"
                  label="Formatter"
                  options={@formatter_options}
                  value={mapping["formatter"]}
                />
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-page-section-button" variant="primary" phx-disable-with="Saving...">
            Save section
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{section: section} = assigns, socket) do
    changeset = Pages.change_section(section)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:type_options, @type_options)
     |> assign(:mode_options, @mode_options)
     |> assign(:source_status_options, @source_status_options)
     |> assign(:operator_options, @operator_options)
     |> assign(:formatter_options, @formatter_options)
     |> assign(:content_type_options, content_type_options(assigns[:content_types] || []))
     |> assign(:source_error, nil)
     |> assign_source_config(source_params(section), mapping_rows(section))
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"page_section" => section_params}, socket) do
    {section_attrs, source_attrs, mappings} = split_section_params(section_params)

    changeset =
      socket.assigns.section
      |> Pages.change_section(section_attrs)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:source_error, nil)
     |> assign_source_config(source_attrs, mapping_rows_from_params(mappings))
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"page_section" => section_params}, socket) do
    {section_attrs, source_attrs, mappings} = split_section_params(section_params)
    save_section(socket, socket.assigns.action, section_attrs, source_attrs, mappings)
  end

  defp save_section(socket, :new_section, section_attrs, source_attrs, mappings) do
    case Pages.create_section_configuration(
           socket.assigns.tenant,
           socket.assigns.page,
           section_attrs,
           source_attrs,
           mappings
         ) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Page section created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, {type, %Ecto.Changeset{} = changeset}} ->
        {:noreply,
         assign_config_error(socket, type, changeset, section_attrs, source_attrs, mappings)}
    end
  end

  defp save_section(socket, :edit_section, section_attrs, source_attrs, mappings) do
    case Pages.update_section_configuration(
           socket.assigns.tenant,
           socket.assigns.section,
           section_attrs,
           source_attrs,
           mappings
         ) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Page section updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, {type, %Ecto.Changeset{} = changeset}} ->
        {:noreply,
         assign_config_error(socket, type, changeset, section_attrs, source_attrs, mappings)}
    end
  end

  defp assign_config_error(socket, type, _changeset, section_attrs, source_attrs, mappings) do
    changeset =
      socket.assigns.section
      |> Pages.change_section(section_attrs)
      |> Map.put(:action, :validate)

    socket
    |> assign(:source_error, config_error_message(type))
    |> assign_source_config(source_attrs, mapping_rows_from_params(mappings))
    |> assign_form(changeset)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset),
    do: assign(socket, :form, to_form(changeset))

  defp assign_source_config(socket, source_params, mapping_rows) do
    socket
    |> assign(:source_params, normalize_source_params(source_params))
    |> assign(:mapping_rows, normalize_mapping_rows(mapping_rows))
  end

  defp split_section_params(section_params) do
    source_attrs = Map.get(section_params, "source", %{})
    mappings = Map.get(section_params, "mappings", %{})
    section_attrs = Map.drop(section_params, ["source", "mappings"])
    {section_attrs, source_attrs, mappings}
  end

  defp fixed_value(form, key) do
    case form[:fixed_data].value do
      value when is_map(value) -> Map.get(value, key)
      _other -> nil
    end
  end

  defp dynamic_mode?(form), do: form[:mode].value == "dynamic"

  defp content_type_options(content_types) do
    [{"Select content type", ""}] ++ Enum.map(content_types, &{&1.name, &1.id})
  end

  defp source_params(%PageSection{source: %SectionSource{} = source}) do
    source_params(source)
  end

  defp source_params(%SectionSource{} = source) do
    %{
      "content_type_id" => source.content_type_id || "",
      "status" => source.status || "published",
      "filters" => source.filters || %{},
      "sort" => source.sort || %{},
      "limit" => source.limit || 6,
      "offset" => source.offset || 0
    }
  end

  defp source_params(_section) do
    %{
      "content_type_id" => "",
      "status" => "published",
      "filters" => %{"field" => "", "op" => "==", "value" => ""},
      "sort" => %{"field" => "published_at", "direction" => "desc"},
      "limit" => 6,
      "offset" => 0
    }
  end

  defp normalize_source_params(params) when is_map(params) do
    defaults = source_params(%PageSection{})

    defaults
    |> Map.merge(string_key_map(params))
    |> Map.update("filters", defaults["filters"], &string_key_map/1)
    |> Map.update("sort", defaults["sort"], &string_key_map/1)
  end

  defp normalize_source_params(_params), do: source_params(%PageSection{})

  defp source_value(params, key), do: Map.get(params, key)
  defp source_filter_value(params, key), do: get_in(params, ["filters", key])
  defp source_sort_value(params, key), do: get_in(params, ["sort", key])

  defp mapping_rows(%PageSection{mappings: mappings}) when is_list(mappings) do
    existing = Map.new(mappings, &{&1.slot, mapping_params(&1)})
    merge_mapping_rows(existing)
  end

  defp mapping_rows(_section), do: Pages.default_section_mappings()

  defp mapping_rows_from_params(params) when is_map(params) do
    params
    |> Map.values()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&string_key_map/1)
    |> Map.new(&{&1["slot"], &1})
    |> merge_mapping_rows()
  end

  defp mapping_rows_from_params(_params), do: Pages.default_section_mappings()

  defp merge_mapping_rows(existing) do
    Enum.map(Pages.default_section_mappings(), fn row ->
      Map.merge(row, Map.get(existing, row["slot"], %{}))
    end)
  end

  defp normalize_mapping_rows(rows) do
    rows
    |> Enum.map(&string_key_map/1)
    |> Enum.sort_by(&(&1["position"] || 0))
  end

  defp mapping_params(%SectionMapping{} = mapping) do
    %{
      "slot" => mapping.slot,
      "source_path" => mapping.source_path,
      "formatter" => mapping.formatter,
      "position" => mapping.position
    }
  end

  defp mapping_label(slot) when is_binary(slot) do
    slot
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp string_key_map(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp string_key_map(_value), do: %{}

  defp config_error_message(:source),
    do: "Source query is invalid. Choose a content type and keep the limit between 1 and 50."

  defp config_error_message(:mapping),
    do: "One mapping is invalid. Use paths like title, slug, payload.name, or payload.price."

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
