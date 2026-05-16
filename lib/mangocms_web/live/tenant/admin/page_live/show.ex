defmodule MangoCMSWeb.Tenant.Admin.PageLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.Pages
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_pages) do
      {:ok, socket} -> {:ok, socket}
      {:redirect, socket} -> {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    tenant = socket.assigns.current_tenant
    page = Pages.get_page!(tenant, id)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:page_title, "Page")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={@page.title}
      subtitle="Review this page and open the visual builder to compose its content tree."
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
          class="btn btn-primary"
        >
          Builder
        </.button>
      </:actions>

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
            <div>
              <dt class="text-sm text-base-content/60">Content tree blocks</dt>
              <dd class="font-medium text-base-content/90">{length(@page.content_tree || [])}</dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="font-semibold text-base-content">Composition</h2>
          <p class="mt-2 text-sm text-base-content/60">
            Pages no longer own section rows. Add reusable sections from the builder sidebar, then
            customize the embedded tree for this page.
          </p>
          <div class="mt-5 flex flex-wrap gap-3">
            <.button navigate={~p"/admin/pages/#{@page}/builder"} variant="primary">
              Open page builder
            </.button>
            <.button navigate={~p"/admin/sections"} class="btn btn-ghost">
              Manage sections
            </.button>
          </div>
        </div>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_status), do: "Unknown"
end
