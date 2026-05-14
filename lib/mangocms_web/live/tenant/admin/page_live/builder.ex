defmodule MangoCMSWeb.Tenant.Admin.PageLive.Builder do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.{ContentEngine, Pages}
  alias MangoCMS.Tenant.Pages.{PageSection, SectionMapping, SectionSource}
  alias MangoCMSWeb.AdminGuard
  alias MangoCMSWeb.Tenant.Admin.PageLive.SectionEditor
  alias MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  @width_options [
    {"Full", "full"},
    {"Half", "half"},
    {"Third", "third"},
    {"Narrow", "narrow"}
  ]

  @section_presets [
    %{
      id: "hero",
      label: "Hero",
      description: "Large intro section",
      icon: "hero-sparkles",
      type: "hero"
    },
    %{
      id: "text",
      label: "Text",
      description: "Editorial copy block",
      icon: "hero-document-text",
      type: "text"
    },
    %{
      id: "cta",
      label: "CTA",
      description: "Centered action band",
      icon: "hero-cursor-arrow-rays",
      type: "cta"
    },
    %{
      id: "dynamic_grid",
      label: "Dynamic Grid",
      description: "Cards from content entries",
      icon: "hero-table-cells",
      type: "feature_grid"
    }
  ]

  @source_status_options SectionSource.status_options()
  @operator_options SectionSource.operator_options()
  @formatter_options SectionMapping.formatter_options()

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_pages) do
      {:ok, socket} -> {:ok, socket}
      {:redirect, socket} -> {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    {:noreply, load_builder(socket, id, params["section"])}
  end

  @impl true
  def handle_event("select_section", %{"id" => id}, socket) do
    {:noreply, select_section(socket, id)}
  end

  def handle_event("save_page_details", %{"page" => page_params}, socket) do
    case Pages.update_page(socket.assigns.current_tenant, socket.assigns.page, page_params) do
      {:ok, page} ->
        {:noreply,
         socket
         |> assign(:page, page)
         |> assign(:page_form, page_form(page))
         |> put_flash(:info, "Page updated")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :page_form, to_form(changeset))}
    end
  end

  def handle_event("add_section", %{"preset" => preset}, socket) do
    tenant = socket.assigns.current_tenant
    page = socket.assigns.page

    case create_preset_section(tenant, page, preset, socket.assigns.content_types) do
      {:ok, section} ->
        {:noreply,
         socket
         |> put_flash(:info, "Section added")
         |> reload_sections(section.id)}

      {:error, message} when is_binary(message) ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, changeset_message(changeset))}

      {:error, {_type, %Ecto.Changeset{} = changeset}} ->
        {:noreply, put_flash(socket, :error, changeset_message(changeset))}
    end
  end

  def handle_event("move_section", %{"id" => id, "direction" => direction}, socket) do
    sections = Pages.list_sections(socket.assigns.current_tenant, socket.assigns.page)

    ids =
      sections
      |> Enum.map(& &1.id)
      |> move_id(id, direction)

    :ok = Pages.reorder_sections(socket.assigns.current_tenant, socket.assigns.page, ids)
    {:noreply, reload_sections(socket, id)}
  end

  def handle_event("reorder_sections", %{"ids" => ids}, socket) when is_list(ids) do
    :ok = Pages.reorder_sections(socket.assigns.current_tenant, socket.assigns.page, ids)
    active_id = socket.assigns.active_section && socket.assigns.active_section.id
    {:noreply, reload_sections(socket, active_id)}
  end

  def handle_event("set_width", %{"id" => id, "width" => width}, socket) do
    if valid_width?(width) do
      section = Pages.get_section!(socket.assigns.current_tenant, id)
      ensure_section_belongs_to_page!(socket.assigns.page, section)

      {:ok, section} =
        Pages.update_section_settings(socket.assigns.current_tenant, section, %{width: width})

      {:noreply, reload_sections(socket, section.id)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_builder_section", %{"section" => section_params}, socket) do
    section = Pages.get_section!(socket.assigns.current_tenant, socket.assigns.active_section.id)
    ensure_section_belongs_to_page!(socket.assigns.page, section)
    {section_attrs, source_attrs, mappings} = split_section_params(section, section_params)

    case Pages.update_section_configuration(
           socket.assigns.current_tenant,
           section,
           section_attrs,
           source_attrs,
           mappings
         ) do
      {:ok, section} ->
        {:noreply,
         socket
         |> put_flash(:info, "Section updated")
         |> reload_sections(section.id)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign_section_error(socket, section, section_params, changeset_message(changeset))}

      {:error, {type, %Ecto.Changeset{} = changeset}} ->
        message = "#{human_label(to_string(type))} #{changeset_message(changeset)}"
        {:noreply, assign_section_error(socket, section, section_params, message)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={"Builder: #{@page.title}"}
      subtitle="Arrange sections, tune layout width, and edit the visible copy from one canvas."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:pages}
    >
      <:actions>
        <.button id="builder-back-button" navigate={~p"/admin/pages/#{@page}"} class="btn btn-ghost">
          Back
        </.button>
        <.button
          :if={@page.status == "published"}
          id="builder-view-public-button"
          href={~p"/#{@page.slug}"}
          class="btn btn-ghost"
        >
          View
        </.button>
        <.button
          id="builder-new-section-button"
          patch={~p"/admin/pages/#{@page}/sections/new"}
          variant="primary"
        >
          <.icon name="hero-plus" class="size-4" /> Advanced add
        </.button>
      </:actions>

      <section id="page-builder" class="mt-8 grid gap-5 xl:grid-cols-[17rem_1fr]">
        <aside class="rounded-lg border border-base-300 bg-base-100 p-4 shadow-sm">
          <div>
            <h2 class="font-semibold text-base-content">Palette</h2>
            <p class="mt-1 text-sm text-base-content/60">Add a section to the end of the page.</p>
          </div>

          <div class="mt-4 grid gap-3">
            <button
              :for={preset <- @section_presets}
              id={"builder-add-#{preset.id}"}
              type="button"
              phx-click="add_section"
              phx-value-preset={preset.id}
              class="group rounded-lg border border-base-300 bg-base-100 p-3 text-left transition hover:border-primary hover:bg-base-200"
            >
              <div class="flex items-start gap-3">
                <span class="rounded-md bg-primary/10 p-2 text-primary">
                  <.icon name={preset.icon} class="size-4" />
                </span>
                <span>
                  <span class="block text-sm font-semibold text-base-content">{preset.label}</span>
                  <span class="mt-0.5 block text-xs text-base-content/60">{preset.description}</span>
                </span>
              </div>
            </button>
          </div>
        </aside>

        <section class="overflow-hidden rounded-lg border border-base-300 bg-base-100 shadow-sm">
          <.form
            for={@page_form}
            id="builder-page-form"
            class="border-b border-base-300 bg-base-100 p-5"
            phx-submit="save_page_details"
          >
            <div class="grid gap-4 xl:grid-cols-[1fr_18rem] xl:items-start">
              <div>
                <p class="text-xs font-semibold uppercase tracking-wide text-primary">Page</p>
                <Shared.editable_text
                  id="builder_page_title"
                  name="page[title]"
                  label="Page title"
                  value={@page_form[:title].value}
                  placeholder="Untitled page"
                  class="py-2 text-3xl font-bold leading-tight text-base-content"
                />
                <Shared.editable_text
                  id="builder_page_subtitle"
                  name="page[seo][subtitle]"
                  label="Page subtitle"
                  value={page_subtitle_value(@page_form)}
                  placeholder="Add a short page subtitle."
                  multiline
                  class="text-base leading-7 text-base-content/70"
                />
              </div>

              <div class="rounded-lg border border-base-300 bg-base-200 p-4">
                <div class="grid gap-3">
                  <.input
                    field={@page_form[:slug]}
                    type="text"
                    label="Slug"
                    class="w-full input input-sm"
                  />
                  <.input
                    field={@page_form[:type]}
                    type="select"
                    label="Type"
                    options={@page_type_options}
                    class="w-full select select-sm"
                  />
                  <.input
                    field={@page_form[:status]}
                    type="select"
                    label="Status"
                    options={@page_status_options}
                    class="w-full select select-sm"
                  />
                  <.input
                    id="builder_page_seo_title"
                    name="page[seo][title]"
                    type="text"
                    label="SEO title"
                    value={page_seo_value(@page_form, "title")}
                    class="w-full input input-sm"
                  />
                  <.input
                    id="builder_page_seo_description"
                    name="page[seo][description]"
                    type="textarea"
                    label="SEO description"
                    value={page_seo_value(@page_form, "description")}
                    rows="2"
                    class="w-full textarea textarea-sm"
                  />
                  <.button
                    id="builder-save-page-button"
                    variant="primary"
                    phx-disable-with="Saving..."
                  >
                    Save page
                  </.button>
                </div>
              </div>
            </div>
          </.form>

          <div class="flex flex-wrap items-center justify-between gap-3 border-b border-base-300 p-4">
            <div>
              <h2 class="font-semibold text-base-content">Canvas</h2>
              <p class="mt-1 text-sm text-base-content/60">
                Select a section to edit it in place. Drag cards to reorder, or use the arrow controls.
              </p>
            </div>
            <span class="rounded-full bg-base-200 px-3 py-1 text-xs font-semibold text-base-content/70">
              {@section_count} sections
            </span>
          </div>

          <div
            id="builder-section-canvas"
            phx-update="stream"
            phx-hook="BuilderSortable"
            class="grid min-h-96 grid-cols-12 gap-4 p-4"
          >
            <div
              id="builder-sections-empty"
              class="col-span-12 hidden only:grid min-h-80 place-items-center rounded-lg border border-dashed border-base-300 bg-base-200 text-sm text-base-content/60"
            >
              Add a section from the palette to start building this page.
            </div>

            <article
              :for={{id, section} <- @streams.sections}
              id={id}
              data-section-id={section.id}
              draggable="true"
              class={builder_section_class(section, @active_section)}
            >
              <div class="mb-3 flex flex-wrap items-center justify-between gap-3">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="cursor-grab rounded-md bg-base-200 px-2 py-1 text-xs font-semibold text-base-content/60">
                    Drag
                  </span>
                  <span class={mode_class(section.mode)}>{human_label(section.mode)}</span>
                  <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                    {section.type}
                  </span>
                </div>
                <span
                  :if={section_active?(section, @active_section)}
                  class="badge badge-primary badge-outline"
                >
                  Editing
                </span>
              </div>

              <%= if section_active?(section, @active_section) do %>
                <.form
                  for={@section_form}
                  id={"builder-section-form-#{section.id}"}
                  phx-submit="save_builder_section"
                >
                  <p
                    :if={@section_error}
                    class="mb-4 rounded-lg bg-error/10 p-3 text-sm text-error"
                  >
                    {@section_error}
                  </p>

                  <SectionEditor.form
                    section={section}
                    form={@section_form}
                    width_options={@width_options}
                    source_params={@source_params}
                    mapping_rows={@mapping_rows}
                    content_type_options={@content_type_options}
                    source_status_options={@source_status_options}
                    operator_options={@operator_options}
                    formatter_options={@formatter_options}
                  />

                  <div class="sticky bottom-3 z-20 mt-4 flex flex-wrap items-center justify-between gap-3 rounded-full border border-base-300 bg-base-100/95 p-2 shadow-lg backdrop-blur">
                    <div class="flex flex-wrap items-center gap-1">
                      <span class="px-3 text-xs font-semibold uppercase tracking-wide text-base-content/50">
                        Size
                      </span>
                      <button
                        :for={{label, width} <- @width_options}
                        id={"builder-section-width-#{width}-#{section.id}"}
                        type="button"
                        phx-click="set_width"
                        phx-value-id={section.id}
                        phx-value-width={width}
                        class={width_button_class(section, width)}
                      >
                        {label}
                      </button>
                    </div>

                    <div class="flex flex-wrap items-center gap-1">
                      <.link
                        id="builder-advanced-edit-link"
                        navigate={~p"/admin/pages/#{@page}/sections/#{section}/edit"}
                        class="btn btn-sm btn-ghost"
                      >
                        Advanced
                      </.link>
                      <button
                        id={"builder-move-up-#{section.id}"}
                        type="button"
                        phx-click="move_section"
                        phx-value-id={section.id}
                        phx-value-direction="up"
                        class="btn btn-square btn-ghost btn-sm"
                        title="Move up"
                      >
                        <.icon name="hero-arrow-up" class="size-4" />
                      </button>
                      <button
                        id={"builder-move-down-#{section.id}"}
                        type="button"
                        phx-click="move_section"
                        phx-value-id={section.id}
                        phx-value-direction="down"
                        class="btn btn-square btn-ghost btn-sm"
                        title="Move down"
                      >
                        <.icon name="hero-arrow-down" class="size-4" />
                      </button>
                      <.button
                        id={"builder-save-section-button-#{section.id}"}
                        variant="primary"
                        phx-disable-with="Saving..."
                      >
                        Save
                      </.button>
                    </div>
                  </div>
                </.form>
              <% else %>
                <button
                  type="button"
                  phx-click="select_section"
                  phx-value-id={section.id}
                  class="block w-full text-left"
                >
                  <SectionEditor.preview section={section} />
                </button>
              <% end %>
            </article>
          </div>
        </section>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp load_builder(socket, page_id, selected_section_id) do
    tenant = socket.assigns.current_tenant
    page = Pages.get_page!(tenant, page_id)
    sections = Pages.list_sections(tenant, page)
    content_types = ContentEngine.list_content_types(tenant)
    active_section = selected_section(sections, selected_section_id)

    socket
    |> assign(:page, page)
    |> assign(:content_types, content_types)
    |> assign(:page_form, page_form(page))
    |> assign(:section_count, length(sections))
    |> assign_section_editor(active_section)
    |> assign(:section_presets, @section_presets)
    |> assign(:page_type_options, MangoCMS.Tenant.Pages.Page.type_options())
    |> assign(:page_status_options, MangoCMS.Tenant.Pages.Page.status_options())
    |> assign(:source_status_options, @source_status_options)
    |> assign(:operator_options, @operator_options)
    |> assign(:formatter_options, @formatter_options)
    |> assign(:content_type_options, content_type_options(content_types))
    |> assign(:width_options, @width_options)
    |> stream(:sections, sections, reset: true)
  end

  defp reload_sections(socket, selected_section_id) do
    sections = Pages.list_sections(socket.assigns.current_tenant, socket.assigns.page)
    active_section = selected_section(sections, selected_section_id)

    socket
    |> assign(:section_count, length(sections))
    |> assign_section_editor(active_section)
    |> stream(:sections, sections, reset: true)
  end

  defp select_section(socket, id) do
    section = Pages.get_section!(socket.assigns.current_tenant, id)
    ensure_section_belongs_to_page!(socket.assigns.page, section)

    reload_sections(socket, section.id)
  end

  defp selected_section([], _id), do: nil
  defp selected_section(sections, nil), do: List.first(sections)

  defp selected_section(sections, id) do
    Enum.find(sections, &(&1.id == id)) || List.first(sections)
  end

  defp assign_section_editor(socket, nil) do
    socket
    |> assign(:active_section, nil)
    |> assign(:section_form, to_form(%{}, as: :section))
    |> assign(:section_error, nil)
    |> assign(:source_params, source_params(nil))
    |> assign(:mapping_rows, Pages.default_section_mappings())
  end

  defp assign_section_editor(socket, %PageSection{} = section) do
    socket
    |> assign(:active_section, section)
    |> assign(:section_form, section_form(section))
    |> assign(:section_error, nil)
    |> assign(:source_params, source_params(section))
    |> assign(:mapping_rows, mapping_rows(section))
  end

  defp assign_section_error(socket, %PageSection{} = section, params, message) do
    socket
    |> assign(:active_section, section)
    |> assign(:section_form, params |> section_form_params(section) |> to_form(as: :section))
    |> assign(:section_error, message)
    |> assign(:source_params, normalize_source_params(Map.get(params, "source", %{})))
    |> assign(:mapping_rows, params |> Map.get("mappings", %{}) |> mapping_rows_from_params())
    |> stream_insert(:sections, section)
  end

  defp page_form(page), do: page |> Pages.change_page() |> to_form()

  defp section_form(%PageSection{} = section) do
    %{}
    |> section_form_params(section)
    |> to_form(as: :section)
  end

  defp section_form_params(params, %PageSection{} = section) when is_map(params) do
    %{
      "type" => Map.get(params, "type", section.type),
      "template_id" => Map.get(params, "template_id", section.template_id),
      "mode" => Map.get(params, "mode", section.mode),
      "position" => Map.get(params, "position", section.position || 0),
      "fixed_data" => Map.get(params, "fixed_data", section.fixed_data || %{}),
      "settings" => Map.get(params, "settings", section.settings || %{})
    }
  end

  defp split_section_params(%PageSection{} = section, params) do
    mode = if Map.get(params, "mode") == "dynamic", do: "dynamic", else: "fixed"

    fixed_data =
      section.fixed_data
      |> safe_map()
      |> Map.merge(safe_map(params["fixed_data"]))
      |> compact_map()

    settings =
      section.settings
      |> safe_map()
      |> Map.merge(safe_map(params["settings"]))
      |> Map.update("width", "full", &normalize_width/1)
      |> compact_map()

    section_attrs = %{
      type: Map.get(params, "type", section.type),
      template_id: Map.get(params, "template_id", section.template_id),
      mode: mode,
      position: Map.get(params, "position", section.position || 0),
      fixed_data: fixed_data,
      settings: settings
    }

    source_attrs =
      if mode == "dynamic" do
        Map.get(params, "source", %{})
      else
        %{}
      end

    mappings =
      if mode == "dynamic" do
        Map.get(params, "mappings", %{})
      else
        []
      end

    {section_attrs, source_attrs, mappings}
  end

  defp content_type_options(content_types) do
    [{"Select content type", ""}] ++ Enum.map(content_types, &{&1.name, &1.id})
  end

  defp source_params(%PageSection{source: %SectionSource{} = source}) do
    normalize_source_params(%{
      "content_type_id" => source.content_type_id || "",
      "status" => source.status || "published",
      "filters" => source.filters || %{},
      "sort" => source.sort || %{},
      "limit" => source.limit || 6,
      "offset" => source.offset || 0
    })
  end

  defp source_params(_section), do: normalize_source_params(%{})

  defp normalize_source_params(params) when is_map(params) do
    defaults = %{
      "content_type_id" => "",
      "status" => "published",
      "filters" => %{"field" => "", "op" => "==", "value" => ""},
      "sort" => %{"field" => "published_at", "direction" => "desc"},
      "limit" => 6,
      "offset" => 0
    }

    defaults
    |> Map.merge(string_key_map(params))
    |> Map.update("filters", defaults["filters"], &string_key_map/1)
    |> Map.update("sort", defaults["sort"], &string_key_map/1)
  end

  defp normalize_source_params(_params), do: source_params(nil)

  defp mapping_rows(%PageSection{mappings: mappings}) when is_list(mappings) do
    existing =
      mappings
      |> Enum.map(&mapping_params/1)
      |> Map.new(&{&1["slot"], &1})

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
    Pages.default_section_mappings()
    |> Enum.map(fn row -> Map.merge(row, Map.get(existing, row["slot"], %{})) end)
    |> Enum.sort_by(&(&1["position"] || 0))
  end

  defp mapping_params(%SectionMapping{} = mapping) do
    %{
      "slot" => mapping.slot,
      "source_path" => mapping.source_path,
      "formatter" => mapping.formatter,
      "settings" => mapping.settings || %{},
      "position" => mapping.position
    }
  end

  defp create_preset_section(tenant, page, "dynamic_grid", content_types) do
    case List.first(content_types) do
      nil ->
        {:error, "Create a content type before adding a dynamic grid section."}

      content_type ->
        Pages.create_section_configuration(
          tenant,
          page,
          %{
            type: "feature_grid",
            template_id: "cards",
            mode: "dynamic",
            position: next_position(tenant, page),
            fixed_data: %{
              "eyebrow" => "Dynamic",
              "title" => "Featured content",
              "subtitle" => "Cards rendered from tenant content entries."
            },
            settings: %{"width" => "full"}
          },
          %{
            content_type_id: content_type.id,
            status: "published",
            filters: %{},
            sort: %{"field" => "published_at", "direction" => "desc"},
            limit: 6,
            offset: 0
          },
          Pages.default_section_mappings()
        )
    end
  end

  defp create_preset_section(tenant, page, preset, _content_types) do
    attrs =
      preset
      |> fixed_preset_attrs()
      |> Map.put(:position, next_position(tenant, page))

    Pages.create_section_configuration(tenant, page, attrs, %{}, [])
  end

  defp fixed_preset_attrs("hero") do
    %{
      type: "hero",
      template_id: "default",
      mode: "fixed",
      fixed_data: %{
        "eyebrow" => "New section",
        "title" => "A clear headline for this page",
        "subtitle" => "Use the inspector to tune this copy.",
        "cta_label" => "Get started",
        "cta_href" => "#"
      },
      settings: %{"width" => "full"}
    }
  end

  defp fixed_preset_attrs("cta") do
    %{
      type: "cta",
      template_id: "default",
      mode: "fixed",
      fixed_data: %{
        "title" => "Ready to take the next step?",
        "subtitle" => "Add a focused call to action for this page.",
        "cta_label" => "Contact us",
        "cta_href" => "#"
      },
      settings: %{"width" => "full"}
    }
  end

  defp fixed_preset_attrs(_preset) do
    %{
      type: "text",
      template_id: "default",
      mode: "fixed",
      fixed_data: %{
        "title" => "New content section",
        "body" => "Add the message, proof, or explanation this page needs."
      },
      settings: %{"width" => "narrow"}
    }
  end

  defp next_position(tenant, page) do
    tenant
    |> Pages.list_sections(page)
    |> Enum.map(& &1.position)
    |> case do
      [] -> 10
      positions -> Enum.max(positions) + 10
    end
  end

  defp move_id(ids, id, "up"), do: move_id_by(ids, id, -1)
  defp move_id(ids, id, "down"), do: move_id_by(ids, id, 1)
  defp move_id(ids, _id, _direction), do: ids

  defp move_id_by(ids, id, offset) do
    index = Enum.find_index(ids, &(&1 == id))

    if is_nil(index) do
      ids
    else
      new_index = max(0, min(length(ids) - 1, index + offset))

      ids
      |> List.delete_at(index)
      |> List.insert_at(new_index, id)
    end
  end

  defp ensure_section_belongs_to_page!(page, section) do
    if section.page_id != page.id do
      raise Ecto.NoResultsError, queryable: PageSection
    end
  end

  defp section_active?(%PageSection{id: id}, %PageSection{id: id}), do: true
  defp section_active?(_section, _active_section), do: false

  defp page_seo_value(form, key) do
    case form[:seo].value do
      value when is_map(value) -> Map.get(value, key)
      _other -> nil
    end
  end

  defp page_subtitle_value(form) do
    page_seo_value(form, "subtitle") || page_seo_value(form, "description")
  end

  defp builder_section_class(section, active_section) do
    [
      "rounded-lg border bg-base-100 p-3 transition hover:border-primary/40 hover:shadow-sm",
      width_class(section),
      active_section && active_section.id == section.id &&
        "border-primary/40 ring-1 ring-primary/20",
      !(active_section && active_section.id == section.id) && "border-base-200"
    ]
  end

  defp width_button_class(section, width) do
    [
      "btn btn-xs",
      section_width(section) == width && "btn-primary",
      section_width(section) != width && "btn-ghost"
    ]
  end

  defp width_class(section) do
    case section_width(section) do
      "half" -> "col-span-12 lg:col-span-6"
      "third" -> "col-span-12 lg:col-span-4"
      "narrow" -> "col-span-12 lg:col-span-8 lg:col-start-3"
      _full -> "col-span-12"
    end
  end

  defp section_width(section), do: settings_value(section, "width", "full")

  defp valid_width?(width), do: width in Enum.map(@width_options, &elem(&1, 1))

  defp normalize_width(width) when is_binary(width) do
    if valid_width?(width), do: width, else: "full"
  end

  defp normalize_width(_width), do: "full"

  defp mode_class("fixed"),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp mode_class("dynamic"),
    do:
      "rounded-full bg-sky-500/10 px-2.5 py-1 text-xs font-semibold text-sky-700 dark:text-sky-300"

  defp mode_class("reference"),
    do: "rounded-full bg-primary/10 px-2.5 py-1 text-xs font-semibold text-primary"

  defp mode_class(_mode),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp human_label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_label(_value), do: "Unknown"

  defp settings_value(%PageSection{settings: settings}, key, fallback) when is_map(settings) do
    case Map.get(settings, key) do
      value when is_binary(value) and value != "" -> value
      _other -> fallback
    end
  end

  defp settings_value(_section, _key, fallback), do: fallback

  defp safe_map(value) when is_map(value), do: value
  defp safe_map(_value), do: %{}

  defp string_key_map(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp string_key_map(_value), do: %{}

  defp compact_map(map) do
    Map.reject(map, fn {_key, value} -> value in [nil, ""] end)
  end

  defp changeset_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, &"#{field} #{&1}")
    end)
    |> List.first()
    |> case do
      nil -> "Section could not be saved"
      message -> message
    end
  end
end
