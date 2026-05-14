defmodule MangoCMSWeb.Tenant.Admin.PageLive.Builder do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.{ContentEngine, Pages}
  alias MangoCMS.Tenant.Pages.PageSection
  alias MangoCMSWeb.AdminGuard

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

  def handle_event("save_active_section", %{"section" => section_params}, socket) do
    section = Pages.get_section!(socket.assigns.current_tenant, socket.assigns.active_section.id)
    ensure_section_belongs_to_page!(socket.assigns.page, section)
    attrs = inspector_attrs(section, section_params)

    case Pages.update_section(socket.assigns.current_tenant, section, attrs) do
      {:ok, section} ->
        {:noreply,
         socket
         |> put_flash(:info, "Section updated")
         |> reload_sections(section.id)}

      {:error, changeset} ->
        {:noreply, assign(socket, :inspector_form, to_form(changeset))}
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

      <section id="page-builder" class="mt-8 grid gap-5 xl:grid-cols-[17rem_1fr_22rem]">
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

        <section class="rounded-lg border border-base-300 bg-base-100 shadow-sm">
          <div class="flex flex-wrap items-center justify-between gap-3 border-b border-base-300 p-4">
            <div>
              <h2 class="font-semibold text-base-content">Canvas</h2>
              <p class="mt-1 text-sm text-base-content/60">
                Drag cards to reorder, or use the arrow controls.
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
              <div class="flex flex-wrap items-start justify-between gap-3">
                <button
                  type="button"
                  phx-click="select_section"
                  phx-value-id={section.id}
                  class="min-w-0 flex-1 text-left"
                >
                  <div class="flex flex-wrap items-center gap-2">
                    <span class="cursor-grab rounded-md bg-base-200 px-2 py-1 text-xs font-semibold text-base-content/60">
                      Drag
                    </span>
                    <span class={mode_class(section.mode)}>{human_label(section.mode)}</span>
                    <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                      {section.type}
                    </span>
                  </div>
                  <h3 class="mt-3 truncate text-lg font-semibold text-base-content">
                    {section_title(section)}
                  </h3>
                  <p class="mt-1 line-clamp-2 text-sm text-base-content/60">
                    {section_summary(section)}
                  </p>
                </button>

                <div class="flex items-center gap-1">
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
                </div>
              </div>

              <div class="mt-4 flex flex-wrap items-center gap-2">
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
            </article>
          </div>
        </section>

        <aside class="rounded-lg border border-base-300 bg-base-100 p-4 shadow-sm">
          <div :if={@active_section} id="builder-inspector">
            <div class="flex items-start justify-between gap-3">
              <div>
                <h2 class="font-semibold text-base-content">Inspector</h2>
                <p class="mt-1 text-sm text-base-content/60">
                  Selected: {section_title(@active_section)}
                </p>
              </div>
              <.link
                id="builder-advanced-edit-link"
                navigate={~p"/admin/pages/#{@page}/sections/#{@active_section}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Advanced
              </.link>
            </div>

            <.form
              for={@inspector_form}
              id="builder-inspector-form"
              class="mt-5 space-y-3"
              phx-submit="save_active_section"
            >
              <.input
                field={@inspector_form[:type]}
                type="select"
                label="Type"
                options={@type_options}
              />
              <.input field={@inspector_form[:template_id]} type="text" label="Template" />
              <.input
                id="builder_inspector_width"
                name="section[settings][width]"
                type="select"
                label="Canvas width"
                options={@width_options}
                value={settings_value(@active_section, "width", "full")}
              />
              <.input
                id="builder_inspector_title"
                name="section[fixed_data][title]"
                type="text"
                label="Title"
                value={fixed_value(@active_section, "title")}
              />
              <.input
                id="builder_inspector_subtitle"
                name="section[fixed_data][subtitle]"
                type="textarea"
                label="Subtitle"
                rows="3"
                value={fixed_value(@active_section, "subtitle")}
              />
              <.input
                id="builder_inspector_body"
                name="section[fixed_data][body]"
                type="textarea"
                label="Body"
                rows="4"
                value={fixed_value(@active_section, "body")}
              />

              <.button
                id="builder-save-inspector-button"
                variant="primary"
                phx-disable-with="Saving..."
              >
                Save inspector
              </.button>
            </.form>
          </div>

          <div :if={!@active_section} class="grid min-h-80 place-items-center text-center">
            <div>
              <h2 class="font-semibold text-base-content">No section selected</h2>
              <p class="mt-1 text-sm text-base-content/60">
                Select a canvas card to edit its visible settings.
              </p>
            </div>
          </div>
        </aside>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp load_builder(socket, page_id, selected_section_id) do
    tenant = socket.assigns.current_tenant
    page = Pages.get_page!(tenant, page_id)
    sections = Pages.list_sections(tenant, page)
    active_section = selected_section(sections, selected_section_id)

    socket
    |> assign(:page, page)
    |> assign(:content_types, ContentEngine.list_content_types(tenant))
    |> assign(:section_count, length(sections))
    |> assign(:active_section, active_section)
    |> assign(:inspector_form, inspector_form(active_section))
    |> assign(:section_presets, @section_presets)
    |> assign(:type_options, PageSection.type_options())
    |> assign(:width_options, @width_options)
    |> stream(:sections, sections, reset: true)
  end

  defp reload_sections(socket, selected_section_id) do
    sections = Pages.list_sections(socket.assigns.current_tenant, socket.assigns.page)
    active_section = selected_section(sections, selected_section_id)

    socket
    |> assign(:section_count, length(sections))
    |> assign(:active_section, active_section)
    |> assign(:inspector_form, inspector_form(active_section))
    |> stream(:sections, sections, reset: true)
  end

  defp select_section(socket, id) do
    section = Pages.get_section!(socket.assigns.current_tenant, id)
    ensure_section_belongs_to_page!(socket.assigns.page, section)

    socket
    |> assign(:active_section, section)
    |> assign(:inspector_form, inspector_form(section))
  end

  defp selected_section([], _id), do: nil
  defp selected_section(sections, nil), do: List.first(sections)

  defp selected_section(sections, id) do
    Enum.find(sections, &(&1.id == id)) || List.first(sections)
  end

  defp inspector_form(nil), do: to_form(%{}, as: :section)

  defp inspector_form(%PageSection{} = section) do
    section
    |> inspector_params()
    |> to_form(as: :section)
  end

  defp inspector_params(%PageSection{} = section) do
    %{
      "type" => section.type,
      "template_id" => section.template_id,
      "fixed_data" => section.fixed_data || %{},
      "settings" => section.settings || %{}
    }
  end

  defp inspector_attrs(%PageSection{} = section, params) do
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

    %{
      type: params["type"] || section.type,
      template_id: params["template_id"] || section.template_id,
      fixed_data: fixed_data,
      settings: settings
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

  defp builder_section_class(section, active_section) do
    [
      "rounded-lg border bg-base-100 p-4 shadow-sm transition hover:border-primary hover:shadow-md",
      width_class(section),
      active_section && active_section.id == section.id && "border-primary ring-2 ring-primary/20",
      !(active_section && active_section.id == section.id) && "border-base-300"
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

  defp section_title(%PageSection{fixed_data: fixed_data}) when is_map(fixed_data) do
    case Map.get(fixed_data, "title") do
      value when is_binary(value) and value != "" -> value
      _other -> "Untitled section"
    end
  end

  defp section_title(_section), do: "Untitled section"

  defp section_summary(%PageSection{mode: "dynamic", source: %{limit: limit}}) do
    "Dynamic content grid · limit #{limit}"
  end

  defp section_summary(%PageSection{mode: "reference", source: %{limit: limit}}) do
    "Referenced content · limit #{limit}"
  end

  defp section_summary(%PageSection{fixed_data: fixed_data}) when is_map(fixed_data) do
    Map.get(fixed_data, "subtitle") || Map.get(fixed_data, "body") || "Fixed content section"
  end

  defp section_summary(_section), do: "Page section"

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

  defp fixed_value(%PageSection{fixed_data: fixed_data}, key) when is_map(fixed_data) do
    Map.get(fixed_data, key)
  end

  defp fixed_value(_section, _key), do: nil

  defp settings_value(%PageSection{settings: settings}, key, fallback) when is_map(settings) do
    case Map.get(settings, key) do
      value when is_binary(value) and value != "" -> value
      _other -> fallback
    end
  end

  defp settings_value(_section, _key, fallback), do: fallback

  defp safe_map(value) when is_map(value), do: value
  defp safe_map(_value), do: %{}

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
