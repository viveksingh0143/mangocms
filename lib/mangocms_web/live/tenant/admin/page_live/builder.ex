defmodule MangoCMSWeb.Tenant.Admin.PageLive.Builder do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.{ContentEngine, Pages}
  alias MangoCMS.Tenant.Pages.{PageSection, SectionMapping, SectionSource}
  alias MangoCMS.Uploads
  alias MangoCMSWeb.AdminGuard
  alias MangoCMSWeb.Tenant.Admin.PageLive.SectionEditor
  alias MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared

  @width_options [
    {"Full", "full"},
    {"Half", "half"},
    {"Third", "third"},
    {"Narrow", "narrow"}
  ]

  @hero_ratio_options [
    {"5:5", "5:5"},
    {"2:8", "2:8"},
    {"8:2", "8:2"},
    {"6:4", "6:4"},
    {"4:6", "4:6"},
    {"7:3", "7:3"},
    {"3:7", "3:7"}
  ]

  @link_target_options [
    {"Same tab", "_self"},
    {"New tab", "_blank"}
  ]

  @text_element_fields ~w(eyebrow title subtitle body)

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
      description: "Optional title and copy",
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
      {:ok, socket} ->
        {:ok,
         allow_upload(socket, :section_image,
           accept: ~w(.jpg .jpeg .png .gif .webp .svg),
           max_entries: 1,
           max_file_size: 5_000_000,
           auto_upload: true
         )}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id} = params, url, socket) do
    {:noreply,
     socket
     |> assign(:tenant_public_base_url, public_base_url(url))
     |> load_builder(id, params["section"])}
  end

  @impl true
  def handle_event("select_section", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> select_section(id)
     |> assign(:selected_canvas_element, selected_canvas_element(%{"kind" => "section"}))
     |> assign(:right_panel, nil)}
  end

  def handle_event("select_canvas_element", %{"section_id" => id} = params, socket) do
    {:noreply,
     socket
     |> select_section_if_needed(id)
     |> assign(:selected_canvas_element, selected_canvas_element(params))
     |> assign(:right_panel, :section_properties)}
  end

  def handle_event("select_canvas_element", params, socket) do
    {:noreply,
     socket
     |> clear_active_section()
     |> assign(:selected_canvas_element, selected_canvas_element(params))
     |> assign(:right_panel, nil)}
  end

  def handle_event("clear_section_focus", _params, socket) do
    {:noreply,
     socket
     |> clear_active_section()
     |> assign(:selected_canvas_element, selected_canvas_element(%{"kind" => "page"}))
     |> assign(:right_panel, nil)}
  end

  def handle_event("toggle_palette", _params, socket) do
    {:noreply, update(socket, :palette_collapsed, &(!&1))}
  end

  def handle_event("edit_page_type", _params, socket) do
    {:noreply, assign(socket, :editing_page_type, true)}
  end

  def handle_event("open_seo_panel", _params, socket) do
    {:noreply, assign(socket, :right_panel, :seo)}
  end

  def handle_event("open_section_properties", %{"id" => id} = params, socket) do
    {:noreply,
     socket
     |> select_section_if_needed(id)
     |> assign(
       :selected_canvas_element,
       selected_canvas_element(params |> Map.put("kind", "section") |> Map.put("section_id", id))
     )
     |> assign(:right_panel, :section_properties)}
  end

  def handle_event("open_section_properties", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_canvas_element, selected_canvas_element(%{"kind" => "section"}))
     |> assign(:right_panel, :section_properties)}
  end

  def handle_event("close_right_panel", _params, socket) do
    {:noreply, assign(socket, :right_panel, nil)}
  end

  def handle_event("save_page_status", %{"page" => page_params}, socket) do
    page_params =
      page_params
      |> Map.take(["status"])
      |> Map.put_new("title", socket.assigns.page.title)
      |> Map.put_new("slug", socket.assigns.page.slug)
      |> Map.put_new("type", socket.assigns.page.type)
      |> Map.put_new("seo", socket.assigns.page.seo || %{})

    case Pages.update_page(socket.assigns.current_tenant, socket.assigns.page, page_params) do
      {:ok, page} ->
        {:noreply,
         socket
         |> assign(:page, page)
         |> assign(:page_form, page_form(page))
         |> put_flash(:info, "Page status updated")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :page_form, to_form(changeset))}
    end
  end

  def handle_event("mark_section_dirty", %{"id" => id}, socket) do
    dirty_section_ids =
      socket.assigns.dirty_section_ids
      |> MapSet.put(id)

    {:noreply, assign(socket, :dirty_section_ids, dirty_section_ids)}
  end

  def handle_event(
        "mark_active_section_dirty",
        _params,
        %{assigns: %{active_section: nil}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event("mark_active_section_dirty", %{"section" => section_params}, socket) do
    section = socket.assigns.active_section
    section_params = merge_current_section_params(socket, section_params)

    dirty_section_ids =
      socket.assigns.dirty_section_ids
      |> MapSet.put(section.id)

    source_params =
      if Map.has_key?(section_params, "source") do
        socket.assigns.source_params
        |> safe_map()
        |> deep_merge_maps(safe_map(Map.get(section_params, "source", %{})))
        |> normalize_source_params()
      else
        socket.assigns.source_params
      end

    mapping_rows =
      if Map.has_key?(section_params, "mappings") do
        section_params
        |> Map.get("mappings", %{})
        |> mapping_rows_from_params()
      else
        mapping_rows(section)
      end

    {:noreply,
     socket
     |> assign(:dirty_section_ids, dirty_section_ids)
     |> assign(
       :section_form,
       section_params |> section_form_params(section) |> to_form(as: :section)
     )
     |> assign(:source_params, source_params)
     |> assign(:mapping_rows, mapping_rows)
     |> stream_insert(:sections, section)}
  end

  def handle_event("mark_active_section_dirty", _params, socket), do: {:noreply, socket}

  def handle_event("save_page_details", %{"page" => page_params}, socket) do
    case Pages.update_page(socket.assigns.current_tenant, socket.assigns.page, page_params) do
      {:ok, page} ->
        {:noreply,
         socket
         |> assign(:page, page)
         |> assign(:page_form, page_form(page))
         |> assign(:editing_page_type, false)
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

  def handle_event("insert_preset_section", %{"preset" => preset} = params, socket) do
    tenant = socket.assigns.current_tenant
    page = socket.assigns.page

    case create_preset_section(tenant, page, preset, socket.assigns.content_types) do
      {:ok, section} ->
        sections = Pages.list_sections(tenant, page)
        target_id = Map.get(params, "target_id")
        placement = Map.get(params, "placement", "after")

        ordered_ids =
          sections
          |> Enum.map(& &1.id)
          |> insert_id(section.id, target_id, placement)

        :ok = Pages.reorder_sections(tenant, page, ordered_ids)

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

  def handle_event("delete_section", %{"id" => id}, socket) do
    section = Pages.get_section!(socket.assigns.current_tenant, id)
    ensure_section_belongs_to_page!(socket.assigns.page, section)
    {:ok, _section} = Pages.delete_section(socket.assigns.current_tenant, section)

    next_active_id =
      socket.assigns.current_tenant
      |> Pages.list_sections(socket.assigns.page)
      |> List.first()
      |> then(&(&1 && &1.id))

    {:noreply,
     socket
     |> clear_dirty_section(id)
     |> put_flash(:info, "Section removed")
     |> reload_sections(next_active_id)}
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

    section_params =
      socket
      |> merge_current_section_params(section_params)
      |> then(&maybe_put_uploaded_image(socket, section, &1))

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
         |> clear_dirty_section(section.id)
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
        <form id="builder-page-status-form" phx-change="save_page_status">
          <label class="sr-only" for="builder-page-status-select">Page status</label>
          <select
            id="builder-page-status-select"
            name="page[status]"
            class="select select-sm w-32"
          >
            <option
              :for={{label, value} <- @page_status_options}
              value={value}
              selected={@page.status == value}
            >
              {label}
            </option>
          </select>
        </form>
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
          id="builder-seo-button"
          phx-click="open_seo_panel"
          class="btn btn-ghost"
        >
          SEO
        </.button>
        <button
          id="builder-save-page-button"
          type="submit"
          form="builder-page-form"
          class="btn btn-primary"
        >
          Save page
        </button>
        <.button
          id="builder-new-section-button"
          patch={~p"/admin/pages/#{@page}/sections/new"}
          class="btn btn-ghost"
        >
          <.icon name="hero-plus" class="size-4" /> Advanced add
        </.button>
      </:actions>

      <section
        id="page-builder"
        class={builder_shell_class(@palette_collapsed, @right_panel)}
        phx-hook="BuilderCanvas"
      >
        <aside id="builder-palette" class={palette_class(@palette_collapsed)}>
          <div class="flex items-center justify-between gap-3">
            <div :if={!@palette_collapsed}>
              <h2 class="font-semibold text-base-content">Palette</h2>
              <p class="mt-1 text-sm text-base-content/60">Add a section.</p>
            </div>
            <button
              id="builder-toggle-palette"
              type="button"
              phx-click="toggle_palette"
              class="btn btn-square btn-ghost btn-sm"
              title={if(@palette_collapsed, do: "Expand palette", else: "Minimize palette")}
            >
              <.icon
                name={if(@palette_collapsed, do: "hero-chevron-right", else: "hero-chevron-left")}
                class="size-4"
              />
            </button>
          </div>

          <div class="mt-4 grid gap-3">
            <button
              :for={preset <- @section_presets}
              id={"builder-add-#{preset.id}"}
              type="button"
              draggable="true"
              data-preset-id={preset.id}
              phx-click="add_section"
              phx-value-preset={preset.id}
              class={[
                "group rounded-lg border border-base-300 bg-base-100 p-3 text-left transition hover:border-primary hover:bg-base-200",
                @palette_collapsed && "btn btn-square"
              ]}
              title={preset.label}
            >
              <div class="flex items-start gap-3">
                <span class="rounded-md bg-primary/10 p-2 text-primary">
                  <.icon name={preset.icon} class="size-4" />
                </span>
                <span :if={!@palette_collapsed}>
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
            <input
              :if={@right_panel != :seo}
              type="hidden"
              name="page[status]"
              value={@page_form[:status].value}
            />
            <input
              :if={@right_panel != :seo}
              type="text"
              name="page[seo][title]"
              value={page_seo_value(@page_form, "title")}
              class="sr-only"
              tabindex="-1"
              aria-hidden="true"
            />
            <input
              :if={@right_panel != :seo}
              type="text"
              name="page[seo][description]"
              value={page_seo_value(@page_form, "description")}
              class="sr-only"
              tabindex="-1"
              aria-hidden="true"
            />

            <div class="max-w-4xl">
              <div class="mb-2">
                <.input
                  :if={@editing_page_type}
                  field={@page_form[:type]}
                  type="select"
                  label="Page type"
                  options={@page_type_options}
                  class="select select-sm w-44"
                />
                <button
                  :if={!@editing_page_type}
                  id="builder-page-type-label"
                  type="button"
                  phx-dblclick="edit_page_type"
                  class="rounded-md px-0 text-xs font-semibold uppercase tracking-wide text-primary outline-none hover:bg-primary/5 focus:bg-primary/10"
                  title="Double click to change page type"
                >
                  {human_label(@page_form[:type].value)}
                </button>
                <input
                  :if={!@editing_page_type}
                  type="hidden"
                  name="page[type]"
                  value={@page_form[:type].value}
                />
              </div>

              <Shared.editable_text
                id="builder_page_title"
                name="page[title]"
                label="Page title"
                value={@page_form[:title].value}
                placeholder="Untitled page"
                class="py-2 text-3xl font-bold leading-tight text-base-content"
              />
              <div class="mt-1 grid gap-1 text-sm font-medium text-base-content/50">
                <.link
                  id="builder-public-page-link"
                  href={public_page_url(@tenant_public_base_url, @page_form[:slug].value)}
                  class="w-fit rounded text-primary underline-offset-4 hover:underline"
                  target="_blank"
                >
                  {public_page_url(@tenant_public_base_url, @page_form[:slug].value)}
                </.link>
                <div class="flex flex-wrap items-center gap-2">
                  <span class="text-xs font-semibold uppercase tracking-wide text-base-content/40">
                    Slug
                  </span>
                  <Shared.editable_text
                    id="builder_page_slug"
                    name="page[slug]"
                    label="Page slug"
                    value={@page_form[:slug].value}
                    placeholder="page-slug"
                    class="inline-flex min-h-0 text-sm font-medium text-base-content/50"
                  />
                </div>
              </div>
              <Shared.editable_text
                id="builder_page_subtitle"
                name="page[seo][subtitle]"
                label="Page subtitle"
                value={page_subtitle_value(@page_form)}
                placeholder="Add a short page subtitle."
                multiline
                class="mt-3 text-base leading-7 text-base-content/70"
              />
            </div>
          </.form>

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
              class={builder_section_class(section, @active_section, @dirty_section_ids)}
            >
              <span
                class="absolute right-24 top-3 z-10 cursor-grab rounded-full border border-base-300 bg-base-100/90 p-2 text-base-content/50 shadow-sm backdrop-blur"
                title="Drag section"
                data-builder-ignore-click
              >
                <.icon name="hero-bars-3" class="size-4" />
              </span>
              <button
                id={"builder-section-gear-#{section.id}"}
                type="button"
                phx-click="open_section_properties"
                phx-value-id={section.id}
                data-builder-ignore-click
                class="absolute right-14 top-3 z-10 rounded-full border border-base-300 bg-base-100/90 p-2 text-base-content/60 shadow-sm backdrop-blur transition hover:border-primary/40 hover:bg-primary/10 hover:text-primary"
                title="Section settings"
              >
                <.icon name="hero-cog-6-tooth" class="size-4" />
              </button>
              <button
                id={"builder-delete-section-#{section.id}"}
                type="button"
                phx-click="delete_section"
                phx-value-id={section.id}
                data-confirm="Remove this section from the page?"
                data-builder-ignore-click
                class="absolute right-3 top-3 z-10 rounded-full border border-error/20 bg-base-100/90 p-2 text-error shadow-sm backdrop-blur transition hover:bg-error/10"
                title="Delete section"
              >
                <.icon name="hero-trash" class="size-4" />
              </button>

              <%= if section_active?(section, @active_section) do %>
                <.form
                  for={@section_form}
                  id={"builder-section-form-#{section.id}"}
                  phx-change="mark_active_section_dirty"
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
                  <.live_file_input upload={@uploads.section_image} class="sr-only" />
                  <.section_bottom_sheet
                    section={section}
                    page={@page}
                    width_options={@width_options}
                    dirty={section_dirty?(section, @dirty_section_ids)}
                  />
                </.form>
              <% else %>
                <button
                  id={"builder-select-section-#{section.id}"}
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

        <.builder_inspector
          :if={@right_panel}
          panel={@right_panel}
          page_form={@page_form}
          active_section={@active_section}
          section_form={@section_form}
          selected_element={@selected_canvas_element}
          uploads={@uploads}
          hero_ratio_options={@hero_ratio_options}
          link_target_options={@link_target_options}
          source_params={@source_params}
          mapping_rows={@mapping_rows}
          content_type_options={@content_type_options}
          source_status_options={@source_status_options}
          operator_options={@operator_options}
          formatter_options={@formatter_options}
        />
      </section>
    </Layouts.tenant_admin>
    """
  end

  attr :panel, :atom, required: true
  attr :page_form, :any, required: true
  attr :active_section, :any, default: nil
  attr :section_form, :any, required: true
  attr :selected_element, :map, required: true
  attr :uploads, :map, required: true
  attr :hero_ratio_options, :list, required: true
  attr :link_target_options, :list, required: true
  attr :source_params, :map, required: true
  attr :mapping_rows, :list, required: true
  attr :content_type_options, :list, required: true
  attr :source_status_options, :list, required: true
  attr :operator_options, :list, required: true
  attr :formatter_options, :list, required: true

  defp builder_inspector(assigns) do
    ~H"""
    <aside
      id="builder-inspector-sidebar"
      class="min-h-[calc(100vh-9rem)] overflow-hidden rounded-2xl border border-base-300 bg-base-100 shadow-sm lg:sticky lg:top-36 lg:h-[calc(100vh-10rem)]"
    >
      <.builder_seo_panel
        :if={@panel == :seo}
        page_form={@page_form}
        form_id="builder-page-form"
      />
      <.section_properties_panel
        :if={@panel == :section_properties and @active_section}
        section={@active_section}
        form={@section_form}
        form_id={"builder-section-form-#{@active_section.id}"}
        selected_element={@selected_element}
        uploads={@uploads}
        hero_ratio_options={@hero_ratio_options}
        link_target_options={@link_target_options}
        source_params={@source_params}
        mapping_rows={@mapping_rows}
        content_type_options={@content_type_options}
        source_status_options={@source_status_options}
        operator_options={@operator_options}
        formatter_options={@formatter_options}
      />
    </aside>
    """
  end

  attr :page_form, :any, required: true
  attr :form_id, :string, required: true

  defp builder_seo_panel(assigns) do
    ~H"""
    <div
      id="builder-seo-panel"
      class="h-full overflow-y-auto p-5"
    >
      <div class="flex items-start justify-between gap-4">
        <div>
          <h2 class="text-lg font-semibold text-base-content">SEO</h2>
          <p class="mt-1 text-sm text-base-content/60">
            Search title and description stay separate from the visible page subtitle.
          </p>
        </div>
        <button
          id="builder-close-seo-panel"
          type="button"
          phx-click="close_right_panel"
          class="btn btn-square btn-ghost btn-sm"
          title="Close SEO panel"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>

      <div class="mt-5 grid gap-4">
        <.input
          id="builder-seo-title"
          name="page[seo][title]"
          type="text"
          label="SEO title"
          value={page_seo_value(@page_form, "title")}
          placeholder="Search result title"
          form={@form_id}
          class="w-full input"
        />
        <.input
          id="builder-seo-description"
          name="page[seo][description]"
          type="textarea"
          label="SEO description"
          value={page_seo_value(@page_form, "description")}
          placeholder="Short search result summary."
          form={@form_id}
          class="min-h-32 w-full textarea"
        />
      </div>
    </div>
    """
  end

  attr :section, PageSection, required: true
  attr :form, :any, required: true
  attr :form_id, :string, required: true
  attr :selected_element, :map, required: true
  attr :uploads, :map, required: true
  attr :hero_ratio_options, :list, required: true
  attr :link_target_options, :list, required: true
  attr :source_params, :map, required: true
  attr :mapping_rows, :list, required: true
  attr :content_type_options, :list, required: true
  attr :source_status_options, :list, required: true
  attr :operator_options, :list, required: true
  attr :formatter_options, :list, required: true

  defp section_properties_panel(assigns) do
    ~H"""
    <div
      id="builder-section-properties-panel"
      class="h-full overflow-y-auto p-5"
    >
      <div class="flex items-start justify-between gap-4">
        <div>
          <h2 class="text-lg font-semibold text-base-content">
            {property_panel_title(@selected_element)}
          </h2>
          <p class="mt-1 text-sm text-base-content/60">
            {property_panel_description(@selected_element)}
          </p>
        </div>
        <button
          id="builder-close-section-properties-panel"
          type="button"
          phx-click="close_right_panel"
          class="btn btn-square btn-ghost btn-sm"
          title="Close section properties"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>

      <div class="mt-5 grid gap-5">
        <.section_style_properties
          :if={selected_element_kind(@selected_element) == "section"}
          section={@section}
          form={@form}
          form_id={@form_id}
          hero_ratio_options={@hero_ratio_options}
        />

        <.section_text_properties
          :if={selected_element_kind(@selected_element) == "section" and @section.mode == "fixed"}
          section={@section}
          form={@form}
          form_id={@form_id}
        />

        <.image_element_properties
          :if={
            selected_element_kind(@selected_element) in ["section", "image"] and
              @section.mode == "fixed"
          }
          section={@section}
          form={@form}
          form_id={@form_id}
          uploads={@uploads}
          target_options={@link_target_options}
        />

        <.link_element_properties
          :if={
            selected_element_kind(@selected_element) in ["section", "link"] and
              @section.mode == "fixed"
          }
          section={@section}
          form={@form}
          form_id={@form_id}
          target_options={@link_target_options}
        />

        <.text_element_properties
          :if={selected_element_kind(@selected_element) == "text"}
          section={@section}
          form={@form}
          form_id={@form_id}
          selected_element={@selected_element}
        />

        <.dynamic_source_properties
          :if={@section.mode == "dynamic" and selected_element_kind(@selected_element) == "section"}
          section={@section}
          source_params={@source_params}
          mapping_rows={@mapping_rows}
          content_type_options={@content_type_options}
          source_status_options={@source_status_options}
          operator_options={@operator_options}
          formatter_options={@formatter_options}
          form_id={@form_id}
        />
      </div>
    </div>
    """
  end

  attr :section, PageSection, required: true
  attr :form, :any, required: true
  attr :form_id, :string, required: true

  defp section_text_properties(assigns) do
    ~H"""
    <section class="grid gap-4 rounded-lg border border-base-300 bg-base-200 p-4">
      <h3 class="font-semibold text-base-content">Text classes</h3>
      <.input
        id={"builder_section_eyebrow_classes_#{@section.id}"}
        name="section[fixed_data][eyebrow_classes]"
        type="text"
        label="Eyebrow classes"
        value={fixed_form_value(@form, "eyebrow_classes")}
        placeholder="text-primary"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_title_classes_#{@section.id}"}
        name="section[fixed_data][title_classes]"
        type="text"
        label="Title classes"
        value={fixed_form_value(@form, "title_classes")}
        placeholder="text-primary max-w-3xl"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_subtitle_classes_#{@section.id}"}
        name="section[fixed_data][subtitle_classes]"
        type="text"
        label="Subtitle classes"
        value={fixed_form_value(@form, "subtitle_classes")}
        placeholder="text-base-content/70"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_body_classes_#{@section.id}"}
        name="section[fixed_data][body_classes]"
        type="text"
        label="Body classes"
        value={fixed_form_value(@form, "body_classes")}
        placeholder="leading-8"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
    </section>
    """
  end

  attr :section, PageSection, required: true
  attr :form, :any, required: true
  attr :form_id, :string, required: true
  attr :hero_ratio_options, :list, required: true

  defp section_style_properties(assigns) do
    ~H"""
    <section class="grid gap-4">
      <.input
        :if={@section.type == "hero"}
        id={"builder_section_ratio_#{@section.id}"}
        name="section[settings][content_ratio]"
        type="select"
        label="Content / image split"
        options={@hero_ratio_options}
        value={settings_form_value(@form, "content_ratio", "5:5")}
        form={@form_id}
        class="w-full select"
        phx-change="mark_active_section_dirty"
      />

      <.input
        id={"builder_section_background_class_#{@section.id}"}
        name="section[settings][background_class]"
        type="text"
        label="Background or gradient classes"
        value={settings_form_value(@form, "background_class")}
        placeholder="bg-base-100 or bg-gradient-to-r from-primary/10 to-base-100"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_border_class_#{@section.id}"}
        name="section[settings][border_class]"
        type="text"
        label="Border color classes"
        value={settings_form_value(@form, "border_class")}
        placeholder="border border-base-300"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_extra_classes_#{@section.id}"}
        name="section[settings][extra_classes]"
        type="textarea"
        label="Extra Tailwind classes"
        value={settings_form_value(@form, "extra_classes")}
        placeholder="shadow-xl ring-1 ring-primary/20"
        form={@form_id}
        class="min-h-28 w-full textarea"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
    </section>
    """
  end

  attr :section, PageSection, required: true
  attr :form, :any, required: true
  attr :form_id, :string, required: true
  attr :selected_element, :map, required: true

  defp text_element_properties(assigns) do
    assigns =
      assigns
      |> assign(:field, text_element_field(assigns.selected_element))
      |> assign(:input_type, text_element_input_type(assigns.selected_element))
      |> assign(:label, text_element_label(assigns.selected_element))

    ~H"""
    <section class="grid gap-4">
      <.input
        id={"builder_section_text_value_#{@field}_#{@section.id}"}
        name={"section[fixed_data][#{@field}]"}
        type={@input_type}
        label={@label}
        value={fixed_form_value(@form, @field)}
        placeholder={"Edit #{String.downcase(@label)}"}
        form={@form_id}
        class={if(@input_type == "textarea", do: "min-h-32 w-full textarea", else: "w-full input")}
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_text_classes_#{@field}_#{@section.id}"}
        name={"section[fixed_data][#{@field}_classes]"}
        type="textarea"
        label="Custom text classes"
        value={fixed_form_value(@form, "#{@field}_classes")}
        placeholder="text-primary max-w-3xl tracking-wide"
        form={@form_id}
        class="min-h-28 w-full textarea"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
    </section>
    """
  end

  attr :section, PageSection, required: true
  attr :form, :any, required: true
  attr :form_id, :string, required: true
  attr :uploads, :map, required: true
  attr :target_options, :list, required: true

  defp image_element_properties(assigns) do
    ~H"""
    <section class="grid gap-4">
      <div class="rounded-lg border border-dashed border-base-300 bg-base-200 p-4">
        <label class="block text-sm font-semibold text-base-content">Upload image</label>
        <label
          for={@uploads.section_image.ref}
          class="btn btn-outline btn-sm mt-3 w-full cursor-pointer"
        >
          Choose image
        </label>
        <div class="mt-3 grid gap-2">
          <div :for={entry <- @uploads.section_image.entries} class="text-xs text-base-content/60">
            {entry.client_name} · {entry.progress}%
          </div>
        </div>
      </div>

      <.input
        id={"builder_section_image_url_#{@section.id}"}
        name="section[fixed_data][image_url]"
        type="text"
        label="Image URL"
        value={fixed_form_value(@form, "image_url")}
        placeholder="/uploads/tenants/.../image.png"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_image_alt_#{@section.id}"}
        name="section[fixed_data][image_alt]"
        type="text"
        label="Alt text"
        value={fixed_form_value(@form, "image_alt")}
        placeholder="Describe the image"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_image_href_#{@section.id}"}
        name="section[fixed_data][image_href]"
        type="text"
        label="Image anchor link"
        value={fixed_form_value(@form, "image_href")}
        placeholder="/about"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_image_target_#{@section.id}"}
        name="section[fixed_data][image_target]"
        type="select"
        label="Anchor target"
        options={@target_options}
        value={fixed_form_value(@form, "image_target") || "_self"}
        form={@form_id}
        class="w-full select"
        phx-change="mark_active_section_dirty"
      />
      <.input
        id={"builder_section_image_title_#{@section.id}"}
        name="section[fixed_data][image_title]"
        type="text"
        label="Image link title"
        value={fixed_form_value(@form, "image_title")}
        placeholder="Small SEO title for the image link"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_image_classes_#{@section.id}"}
        name="section[fixed_data][image_classes]"
        type="textarea"
        label="Image classes"
        value={fixed_form_value(@form, "image_classes")}
        placeholder="object-cover rounded-xl shadow-lg"
        form={@form_id}
        class="min-h-28 w-full textarea"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
    </section>
    """
  end

  attr :section, PageSection, required: true
  attr :form, :any, required: true
  attr :form_id, :string, required: true
  attr :target_options, :list, required: true

  defp link_element_properties(assigns) do
    ~H"""
    <section class="grid gap-4">
      <.input
        id={"builder_section_cta_label_#{@section.id}"}
        name="section[fixed_data][cta_label]"
        type="text"
        label="Button/link text"
        value={fixed_form_value(@form, "cta_label")}
        placeholder="Get started"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_cta_href_#{@section.id}"}
        name="section[fixed_data][cta_href]"
        type="text"
        label="Button/link href"
        value={fixed_form_value(@form, "cta_href")}
        placeholder="/contact or https://example.com"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_cta_target_#{@section.id}"}
        name="section[fixed_data][cta_target]"
        type="select"
        label="Target"
        options={@target_options}
        value={fixed_form_value(@form, "cta_target") || "_self"}
        form={@form_id}
        class="w-full select"
        phx-change="mark_active_section_dirty"
      />
      <.input
        id={"builder_section_cta_title_#{@section.id}"}
        name="section[fixed_data][cta_title]"
        type="text"
        label="Link title"
        value={fixed_form_value(@form, "cta_title")}
        placeholder="Small SEO title"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_cta_text_class_#{@section.id}"}
        name="section[fixed_data][cta_text_class]"
        type="text"
        label="Text color classes"
        value={fixed_form_value(@form, "cta_text_class")}
        placeholder="text-white"
        form={@form_id}
        class="w-full input"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
      <.input
        id={"builder_section_cta_classes_#{@section.id}"}
        name="section[fixed_data][cta_classes]"
        type="textarea"
        label="Custom button/link classes"
        value={fixed_form_value(@form, "cta_classes")}
        placeholder="btn-primary shadow-lg"
        form={@form_id}
        class="min-h-28 w-full textarea"
        phx-change="mark_active_section_dirty"
        phx-debounce="300"
      />
    </section>
    """
  end

  attr :section, PageSection, required: true
  attr :form_id, :string, required: true
  attr :source_params, :map, required: true
  attr :mapping_rows, :list, required: true
  attr :content_type_options, :list, required: true
  attr :source_status_options, :list, required: true
  attr :operator_options, :list, required: true
  attr :formatter_options, :list, required: true

  defp dynamic_source_properties(assigns) do
    ~H"""
    <section class="grid gap-5">
      <div class="rounded-lg border border-base-300 bg-base-200 p-4">
        <h3 class="font-semibold text-base-content">Dynamic source</h3>
        <p class="mt-1 text-sm text-base-content/60">
          Choose the content pool, filters, and order for this section.
        </p>

        <div class="mt-4 grid gap-4 sm:grid-cols-2">
          <.input
            id={"builder_dynamic_source_content_type_#{@section.id}"}
            name="section[source][content_type_id]"
            type="select"
            label="Content type"
            options={@content_type_options}
            value={Shared.source_value(@source_params, "content_type_id")}
            form={@form_id}
            class="w-full select"
            phx-change="mark_active_section_dirty"
          />
          <.input
            id={"builder_dynamic_source_status_#{@section.id}"}
            name="section[source][status]"
            type="select"
            label="Status"
            options={@source_status_options}
            value={Shared.source_value(@source_params, "status")}
            form={@form_id}
            class="w-full select"
            phx-change="mark_active_section_dirty"
          />
          <.input
            id={"builder_dynamic_source_limit_#{@section.id}"}
            name="section[source][limit]"
            type="number"
            label="Limit"
            min="1"
            max="50"
            value={Shared.source_value(@source_params, "limit")}
            form={@form_id}
            class="w-full input"
            phx-change="mark_active_section_dirty"
          />
          <.input
            id={"builder_dynamic_source_offset_#{@section.id}"}
            name="section[source][offset]"
            type="number"
            label="Offset"
            min="0"
            value={Shared.source_value(@source_params, "offset")}
            form={@form_id}
            class="w-full input"
            phx-change="mark_active_section_dirty"
          />
        </div>

        <div class="mt-4 grid gap-4">
          <.input
            id={"builder_dynamic_filter_field_#{@section.id}"}
            name="section[source][filters][field]"
            type="text"
            label="Filter field"
            value={Shared.source_filter_value(@source_params, "field")}
            placeholder="rating"
            form={@form_id}
            class="w-full input"
            phx-change="mark_active_section_dirty"
            phx-debounce="300"
          />
          <.input
            id={"builder_dynamic_filter_op_#{@section.id}"}
            name="section[source][filters][op]"
            type="select"
            label="Operator"
            options={@operator_options}
            value={Shared.source_filter_value(@source_params, "op")}
            form={@form_id}
            class="w-full select"
            phx-change="mark_active_section_dirty"
          />
          <.input
            id={"builder_dynamic_filter_value_#{@section.id}"}
            name="section[source][filters][value]"
            type="text"
            label="Filter value"
            value={Shared.source_filter_value(@source_params, "value")}
            placeholder="5"
            form={@form_id}
            class="w-full input"
            phx-change="mark_active_section_dirty"
            phx-debounce="300"
          />
        </div>

        <div class="mt-4 grid gap-4 sm:grid-cols-2">
          <.input
            id={"builder_dynamic_sort_field_#{@section.id}"}
            name="section[source][sort][field]"
            type="text"
            label="Sort field"
            value={Shared.source_sort_value(@source_params, "field")}
            placeholder="published_at"
            form={@form_id}
            class="w-full input"
            phx-change="mark_active_section_dirty"
            phx-debounce="300"
          />
          <.input
            id={"builder_dynamic_sort_direction_#{@section.id}"}
            name="section[source][sort][direction]"
            type="select"
            label="Sort direction"
            options={[{"Descending", "desc"}, {"Ascending", "asc"}]}
            value={Shared.source_sort_value(@source_params, "direction")}
            form={@form_id}
            class="w-full select"
            phx-change="mark_active_section_dirty"
          />
        </div>
      </div>

      <div class="grid gap-3">
        <h3 class="font-semibold text-base-content">Field mappings</h3>
        <div
          :for={{mapping, index} <- Enum.with_index(@mapping_rows)}
          class="rounded-lg border border-base-300 bg-base-100 p-3"
        >
          <input
            type="hidden"
            name={"section[mappings][#{index}][slot]"}
            value={mapping["slot"]}
            form={@form_id}
          />
          <input
            type="hidden"
            name={"section[mappings][#{index}][position]"}
            value={mapping["position"]}
            form={@form_id}
          />
          <p class="text-xs font-semibold uppercase text-base-content/50">
            {Shared.mapping_label(mapping["slot"])}
          </p>
          <.input
            id={"builder_dynamic_mapping_#{@section.id}_#{mapping["slot"]}_source"}
            name={"section[mappings][#{index}][source_path]"}
            type="text"
            label="Path"
            value={mapping["source_path"]}
            placeholder="payload.name"
            form={@form_id}
            class="w-full input input-sm"
            phx-change="mark_active_section_dirty"
            phx-debounce="300"
          />
          <.input
            id={"builder_dynamic_mapping_#{@section.id}_#{mapping["slot"]}_formatter"}
            name={"section[mappings][#{index}][formatter]"}
            type="select"
            label="Formatter"
            options={@formatter_options}
            value={mapping["formatter"]}
            form={@form_id}
            class="w-full select select-sm"
            phx-change="mark_active_section_dirty"
          />
        </div>
      </div>
    </section>
    """
  end

  attr :section, PageSection, required: true
  attr :page, :any, required: true
  attr :width_options, :list, required: true
  attr :dirty, :boolean, required: true

  defp section_bottom_sheet(assigns) do
    ~H"""
    <div
      id={"builder-section-bottom-sheet-#{@section.id}"}
      class="fixed inset-x-4 bottom-4 z-40 rounded-2xl border border-base-300 bg-base-100/95 p-3 shadow-2xl backdrop-blur lg:left-8 lg:right-8"
    >
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div class="flex flex-wrap items-center gap-2">
          <span class="rounded-full bg-base-200 px-3 py-1 text-xs font-semibold text-base-content/70">
            {human_label(@section.type)}
          </span>
          <span class={mode_class(@section.mode)}>{human_label(@section.mode)}</span>
          <span class="rounded-full bg-base-200 px-3 py-1 text-xs font-semibold text-base-content/70">
            {human_label(@section.template_id)}
          </span>
          <span
            :if={@dirty}
            class="rounded-full bg-warning/15 px-3 py-1 text-xs font-semibold text-warning"
          >
            Unsaved
          </span>
        </div>

        <div class="flex flex-wrap items-center gap-1">
          <button
            :for={{label, width} <- @width_options}
            id={"builder-section-width-#{width}-#{@section.id}"}
            type="button"
            phx-click="set_width"
            phx-value-id={@section.id}
            phx-value-width={width}
            class={width_button_class(@section, width)}
            title={"Set section width to #{label}"}
          >
            {label}
          </button>
        </div>

        <div class="flex flex-wrap items-center gap-1">
          <button
            id={"builder-section-properties-button-#{@section.id}"}
            type="button"
            phx-click="open_section_properties"
            phx-value-id={@section.id}
            class="btn btn-sm btn-ghost"
          >
            Properties
          </button>
          <.link
            id="builder-advanced-edit-link"
            navigate={~p"/admin/pages/#{@page}/sections/#{@section}/edit"}
            class="btn btn-sm btn-ghost"
          >
            Advanced
          </.link>
          <button
            id={"builder-move-up-#{@section.id}"}
            type="button"
            phx-click="move_section"
            phx-value-id={@section.id}
            phx-value-direction="up"
            class="btn btn-square btn-ghost btn-sm"
            title="Move up"
          >
            <.icon name="hero-arrow-up" class="size-4" />
          </button>
          <button
            id={"builder-move-down-#{@section.id}"}
            type="button"
            phx-click="move_section"
            phx-value-id={@section.id}
            phx-value-direction="down"
            class="btn btn-square btn-ghost btn-sm"
            title="Move down"
          >
            <.icon name="hero-arrow-down" class="size-4" />
          </button>
          <.button
            id={"builder-save-section-button-#{@section.id}"}
            variant="primary"
            phx-disable-with="Saving..."
          >
            Save
          </.button>
        </div>
      </div>
    </div>
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
    |> assign(:hero_ratio_options, @hero_ratio_options)
    |> assign(:link_target_options, @link_target_options)
    |> assign_new(:palette_collapsed, fn -> false end)
    |> assign_new(:right_panel, fn -> nil end)
    |> assign_new(:editing_page_type, fn -> false end)
    |> assign_new(:dirty_section_ids, fn -> MapSet.new() end)
    |> assign_new(:selected_canvas_element, fn ->
      selected_canvas_element(%{"kind" => "section"})
    end)
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

  defp clear_active_section(socket) do
    sections = Pages.list_sections(socket.assigns.current_tenant, socket.assigns.page)

    socket
    |> assign(:section_count, length(sections))
    |> assign_section_editor(nil)
    |> stream(:sections, sections, reset: true)
  end

  defp select_section(socket, id) do
    section = Pages.get_section!(socket.assigns.current_tenant, id)
    ensure_section_belongs_to_page!(socket.assigns.page, section)

    reload_sections(socket, section.id)
  end

  defp select_section_if_needed(%{assigns: %{active_section: %PageSection{id: id}}} = socket, id),
    do: socket

  defp select_section_if_needed(socket, id), do: select_section(socket, id)

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

  defp public_base_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} = uri when is_binary(scheme) and is_binary(host) ->
        "#{scheme}://#{host}#{public_port(uri)}"

      _uri ->
        ""
    end
  end

  defp public_base_url(_url), do: ""

  defp public_port(%URI{scheme: "http", port: port}) when port in [nil, 80], do: ""
  defp public_port(%URI{scheme: "https", port: port}) when port in [nil, 443], do: ""
  defp public_port(%URI{port: nil}), do: ""
  defp public_port(%URI{port: port}), do: ":#{port}"

  defp public_page_url(base_url, slug) do
    slug =
      slug
      |> to_string()
      |> String.trim()
      |> String.trim("/")

    base_url = String.trim_trailing(to_string(base_url), "/")

    if slug == "" do
      base_url <> "/"
    else
      base_url <> "/" <> slug
    end
  end

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
      "fixed_data" =>
        section.fixed_data
        |> safe_map()
        |> Map.merge(safe_map(Map.get(params, "fixed_data", %{}))),
      "settings" =>
        section.settings
        |> safe_map()
        |> Map.merge(safe_map(Map.get(params, "settings", %{})))
    }
  end

  defp merge_current_section_params(socket, params) when is_map(params) do
    socket
    |> current_section_params()
    |> deep_merge_maps(string_key_map(params))
  end

  defp current_section_params(socket) do
    form = socket.assigns.section_form

    %{
      "type" => form_value(form, :type),
      "template_id" => form_value(form, :template_id),
      "mode" => form_value(form, :mode),
      "position" => form_value(form, :position),
      "fixed_data" => form_map_value(form, :fixed_data),
      "settings" => form_map_value(form, :settings),
      "source" => socket.assigns.source_params,
      "mappings" => mapping_rows_to_params(socket.assigns.mapping_rows)
    }
  end

  defp form_value(form, field), do: form[field].value

  defp form_map_value(form, field) do
    form[field].value
    |> safe_map()
    |> string_key_map()
  end

  defp mapping_rows_to_params(rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Map.new(fn {row, index} -> {Integer.to_string(index), row} end)
  end

  defp mapping_rows_to_params(_rows), do: %{}

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

  defp insert_id(ids, id, target_id, placement) do
    ids = List.delete(ids, id)
    index = Enum.find_index(ids, &(&1 == target_id))

    cond do
      is_nil(index) ->
        ids ++ [id]

      placement == "before" ->
        List.insert_at(ids, index, id)

      true ->
        List.insert_at(ids, index + 1, id)
    end
  end

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
    page_seo_value(form, "subtitle")
  end

  defp selected_canvas_element(params) when is_map(params) do
    %{
      "kind" => Map.get(params, "kind", "section"),
      "field" => Map.get(params, "field"),
      "section_id" => Map.get(params, "section_id")
    }
  end

  defp selected_element_kind(%{"kind" => kind}) when is_binary(kind), do: kind
  defp selected_element_kind(_element), do: "section"

  defp property_panel_title(element) do
    case selected_element_kind(element) do
      "image" -> "Image properties"
      "link" -> "Link properties"
      "text" -> "#{text_element_label(element)} properties"
      _section -> "Section properties"
    end
  end

  defp property_panel_description(element) do
    case selected_element_kind(element) do
      "image" -> "Image source, upload, alt text, and optional anchor settings."
      "link" -> "Href, target, title, text color, and custom button classes."
      "text" -> "Edit this text directly or tune its custom classes here."
      _section -> "Layout, background, border, classes, and dynamic source settings."
    end
  end

  defp text_element_field(%{"field" => field}) when field in @text_element_fields, do: field
  defp text_element_field(_element), do: "title"

  defp text_element_input_type(%{"field" => field}) when field in ["subtitle", "body"],
    do: "textarea"

  defp text_element_input_type(_element), do: "text"

  defp text_element_label(element) do
    element
    |> text_element_field()
    |> human_label()
  end

  defp builder_section_class(section, active_section, dirty_section_ids) do
    [
      "relative rounded-lg border bg-base-100 p-3 transition hover:border-primary/40 hover:shadow-sm",
      width_class(section),
      section_dirty?(section, dirty_section_ids) && "bg-warning/5",
      active_section && active_section.id == section.id &&
        "border-primary/40 ring-1 ring-primary/20",
      !(active_section && active_section.id == section.id) && "border-base-200"
    ]
  end

  defp section_dirty?(%PageSection{id: id}, %MapSet{} = dirty_section_ids) do
    MapSet.member?(dirty_section_ids, id)
  end

  defp section_dirty?(_section, _dirty_section_ids), do: false

  defp clear_dirty_section(socket, section_id) do
    update(socket, :dirty_section_ids, &MapSet.delete(&1, section_id))
  end

  defp fixed_form_value(form, key) do
    Shared.fixed_value(form, key)
  end

  defp settings_form_value(form, key, fallback \\ nil) do
    case form[:settings].value do
      value when is_map(value) -> Map.get(value, key, fallback)
      _other -> fallback
    end
  end

  defp maybe_put_uploaded_image(socket, section, section_params) do
    consume_uploaded_entries(socket, :section_image, fn meta, entry ->
      {:ok,
       Uploads.store_live_upload!(entry, meta, {:tenant, socket.assigns.current_tenant},
         type: ["sections", section.id, "images"]
       )}
    end)
    |> case do
      [image_url | _rest] ->
        Map.update(section_params, "fixed_data", %{"image_url" => image_url}, fn fixed_data ->
          fixed_data
          |> safe_map()
          |> Map.put("image_url", image_url)
        end)

      [] ->
        section_params
    end
  end

  defp palette_class(true) do
    [
      "min-h-[calc(100vh-9rem)] overflow-hidden rounded-2xl border border-base-300 lg:sticky lg:top-36 lg:h-[calc(100vh-10rem)]",
      "bg-base-100 p-2 shadow-sm"
    ]
  end

  defp palette_class(false) do
    [
      "min-h-[calc(100vh-9rem)] overflow-y-auto rounded-2xl border border-base-300 lg:sticky lg:top-36 lg:h-[calc(100vh-10rem)]",
      "bg-base-100 p-4 shadow-sm"
    ]
  end

  defp builder_shell_class(true, nil) do
    "relative grid gap-5 lg:grid-cols-[4rem_minmax(0,1fr)]"
  end

  defp builder_shell_class(false, nil) do
    "relative grid gap-5 lg:grid-cols-[17rem_minmax(0,1fr)]"
  end

  defp builder_shell_class(true, _panel) do
    "relative grid gap-5 xl:grid-cols-[4rem_minmax(0,1fr)_22rem]"
  end

  defp builder_shell_class(false, _panel) do
    "relative grid gap-5 xl:grid-cols-[17rem_minmax(0,1fr)_22rem]"
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

  defp deep_merge_maps(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      if is_map(left_value) and is_map(right_value) do
        deep_merge_maps(left_value, right_value)
      else
        right_value
      end
    end)
  end

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
