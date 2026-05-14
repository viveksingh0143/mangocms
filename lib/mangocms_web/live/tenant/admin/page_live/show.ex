defmodule MangoCMSWeb.Tenant.Admin.PageLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.{ContentEngine, Pages}
  alias MangoCMS.Tenant.Pages.PageSection
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_pages) do
      {:ok, socket} -> {:ok, socket}
      {:redirect, socket} -> {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    tenant = socket.assigns.current_tenant
    page = Pages.get_page!(tenant, id)

    socket =
      socket
      |> assign(:page, page)
      |> assign(:content_types, ContentEngine.list_content_types(tenant))
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign_section(socket.assigns.live_action, params)
      |> stream_sections(page)

    {:noreply, socket}
  end

  defp assign_section(socket, :new_section, _params) do
    assign(socket, :section, %PageSection{
      page_id: socket.assigns.page.id,
      position: next_section_position(socket)
    })
  end

  defp assign_section(socket, :edit_section, %{"section_id" => section_id}) do
    section = Pages.get_section!(socket.assigns.current_tenant, section_id)
    ensure_section_belongs_to_page!(socket.assigns.page, section)
    assign(socket, :section, section)
  end

  defp assign_section(socket, :show, _params), do: assign(socket, :section, nil)

  @impl true
  def handle_info(
        {MangoCMSWeb.Tenant.Admin.PageLive.SectionFormComponent, {:saved, _section}},
        socket
      ) do
    {:noreply, stream_sections(socket, socket.assigns.page)}
  end

  @impl true
  def handle_event("delete_section", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    section = Pages.get_section!(tenant, id)
    ensure_section_belongs_to_page!(socket.assigns.page, section)
    {:ok, _section} = Pages.delete_section(tenant, section)

    {:noreply, stream_delete(socket, :sections, section)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={@page.title}
      subtitle="Compose this page from ordered sections."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:pages}
    >
      <:actions>
        <.button id="back-to-pages-button" navigate={~p"/admin/pages"} class="btn btn-ghost">
          Back
        </.button>
        <.button
          :if={@page.status == "published"}
          id="view-public-page-button"
          href={~p"/#{@page.slug}"}
          class="btn btn-ghost"
        >
          View
        </.button>
        <.button
          id="page-builder-button"
          navigate={~p"/admin/pages/#{@page}/builder"}
          class="btn btn-ghost"
        >
          Builder
        </.button>
        <.button
          id="new-page-section-button"
          patch={~p"/admin/pages/#{@page}/sections/new"}
          variant="primary"
        >
          <.icon name="hero-plus" class="size-4" /> New section
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new_section, :edit_section]}
        module={MangoCMSWeb.Tenant.Admin.PageLive.SectionFormComponent}
        id={@section.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        page={@page}
        section={@section}
        content_types={@content_types}
        patch={~p"/admin/pages/#{@page}"}
      />

      <section id="page-detail" class="mt-8 grid gap-4 lg:grid-cols-[0.8fr_1.2fr]">
        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Page</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-base-content/60">Slug</dt>
              <dd class="font-semibold text-base-content">/{@page.slug}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Type</dt>
              <dd class="font-medium text-base-content/90">{human_status(@page.type)}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Status</dt>
              <dd class="font-medium text-base-content/90">{human_status(@page.status)}</dd>
            </div>
          </dl>
        </div>

        <div class="overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
          <div class="border-b border-base-300 p-5">
            <h2 class="font-semibold text-base-content">Sections</h2>
            <p class="mt-1 text-sm text-base-content/60">
              Fixed sections render directly. Dynamic and reference sections use source queries and slot mappings.
            </p>
          </div>

          <div id="page-sections" phx-update="stream" class="divide-y divide-base-300">
            <div
              id="page-sections-empty"
              class="hidden only:block p-10 text-center text-sm text-base-content/60"
            >
              No sections yet. Add a fixed hero or text section to render this page.
            </div>

            <div
              :for={{id, section} <- @streams.sections}
              id={id}
              class="grid gap-4 p-5 transition hover:bg-base-200 md:grid-cols-[1fr_0.9fr_auto] md:items-center"
            >
              <div>
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-semibold text-base-content">{section_title(section)}</span>
                  <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                    {section.type}
                  </span>
                </div>
                <p class="mt-1 text-sm text-base-content/60">
                  Template {section.template_id} · position {section.position}
                </p>
                <p :if={source_summary(section)} class="mt-1 text-sm text-base-content/60">
                  {source_summary(section)}
                </p>
              </div>

              <div class="flex flex-wrap gap-2">
                <span class={mode_class(section.mode)}>{human_status(section.mode)}</span>
                <span
                  :if={mapping_count(section) > 0}
                  class="rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"
                >
                  {mapping_count(section)} mappings
                </span>
              </div>

              <div class="flex items-center gap-3 md:justify-end">
                <.link
                  id={"edit-page-section-#{section.id}"}
                  patch={~p"/admin/pages/#{@page}/sections/#{section}/edit"}
                  class="btn btn-sm btn-ghost"
                >
                  Edit
                </.link>
                <button
                  id={"delete-page-section-#{section.id}"}
                  type="button"
                  phx-click="delete_section"
                  phx-value-id={section.id}
                  data-confirm="Delete this page section?"
                  class="btn btn-sm btn-ghost text-error"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp stream_sections(socket, page) do
    sections = Pages.list_sections(socket.assigns.current_tenant, page)
    stream(socket, :sections, sections, reset: true)
  end

  defp next_section_position(socket) do
    socket.assigns.current_tenant
    |> Pages.list_sections(socket.assigns.page)
    |> Enum.map(& &1.position)
    |> case do
      [] -> 0
      positions -> Enum.max(positions) + 10
    end
  end

  defp ensure_section_belongs_to_page!(page, section) do
    if section.page_id != page.id do
      raise Ecto.NoResultsError, queryable: PageSection
    end
  end

  defp page_title(:show), do: "Page"
  defp page_title(:new_section), do: "New page section"
  defp page_title(:edit_section), do: "Edit page section"

  defp section_title(%PageSection{fixed_data: fixed_data}) when is_map(fixed_data) do
    case Map.get(fixed_data, "title") do
      value when is_binary(value) and value != "" -> value
      _other -> "Untitled section"
    end
  end

  defp section_title(_section), do: "Untitled section"

  defp source_summary(%PageSection{source: %{content_type_id: content_type_id, limit: limit}})
       when is_binary(content_type_id) do
    "Source #{String.slice(content_type_id, 0, 8)} · limit #{limit}"
  end

  defp source_summary(_section), do: nil

  defp mapping_count(%PageSection{mappings: mappings}) when is_list(mappings),
    do: length(mappings)

  defp mapping_count(_section), do: 0

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"

  defp mode_class("fixed"),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp mode_class("dynamic"),
    do:
      "rounded-full bg-sky-500/10 px-2.5 py-1 text-xs font-semibold text-sky-700 dark:text-sky-300"

  defp mode_class("reference"),
    do: "rounded-full bg-primary/10 px-2.5 py-1 text-xs font-semibold text-primary"

  defp mode_class(_),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"
end
