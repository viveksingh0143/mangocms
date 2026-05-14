defmodule MangoCMSWeb.Tenant.Admin.PageLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.Pages
  alias MangoCMS.Tenant.Pages.Page
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_pages) do
      {:ok, socket} ->
        tenant = socket.assigns.current_tenant

        {:ok, stream(socket, :pages, Pages.list_pages(tenant))}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit page")
    |> assign(:page, Pages.get_page!(socket.assigns.current_tenant, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New page")
    |> assign(:page, %Page{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Pages")
    |> assign(:page, nil)
  end

  @impl true
  def handle_info({MangoCMSWeb.Tenant.Admin.PageLive.FormComponent, {:saved, page}}, socket) do
    {:noreply, stream_insert(socket, :pages, page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    page = Pages.get_page!(tenant, id)
    {:ok, _page} = Pages.delete_page(tenant, page)

    {:noreply, stream_delete(socket, :pages, page)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title="Pages"
      subtitle="Create tenant pages and compose them from fixed or dynamic sections."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:pages}
    >
      <:actions>
        <.button id="new-page-button" patch={~p"/admin/pages/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> New page
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Tenant.Admin.PageLive.FormComponent}
        id={@page.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        page={@page}
        patch={~p"/admin/pages"}
      />

      <section class="mt-8 overflow-hidden rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm transition-colors">
        <div id="pages" phx-update="stream" class="divide-y divide-base-300">
          <div
            id="pages-empty"
            class="hidden only:block p-10 text-center text-sm text-base-content/60"
          >
            No pages have been created for this tenant.
          </div>

          <div
            :for={{id, page} <- @streams.pages}
            id={id}
            class="grid gap-4 p-5 transition hover:bg-base-200 lg:grid-cols-[1.3fr_0.8fr_0.7fr_auto] lg:items-center"
          >
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <.link
                  navigate={~p"/admin/pages/#{page}"}
                  class="font-semibold text-base-content hover:text-primary"
                >
                  {page.title}
                </.link>
                <span class="rounded-full bg-base-200 px-2 py-0.5 text-xs font-medium text-base-content/70">
                  /{page.slug}
                </span>
              </div>
              <p class="mt-1 text-sm text-base-content/60">{seo_description(page)}</p>
            </div>

            <div class="text-sm text-base-content/70">
              <p class="font-medium text-base-content/90">{human_status(page.type)}</p>
              <p>{published_label(page)}</p>
            </div>

            <div>
              <span class={status_class(page.status)}>{human_status(page.status)}</span>
            </div>

            <div class="flex flex-wrap items-center gap-3 lg:justify-end">
              <.link
                id={"show-page-#{page.id}"}
                navigate={~p"/admin/pages/#{page}"}
                class="btn btn-sm btn-ghost"
              >
                Sections
              </.link>
              <.link
                id={"builder-page-#{page.id}"}
                navigate={~p"/admin/pages/#{page}/builder"}
                class="btn btn-sm btn-ghost"
              >
                Builder
              </.link>
              <.link
                id={"edit-page-#{page.id}"}
                patch={~p"/admin/pages/#{page}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Edit
              </.link>
              <.link
                :if={page.status == "published"}
                id={"view-page-#{page.id}"}
                href={~p"/#{page.slug}"}
                class="btn btn-sm btn-ghost"
              >
                View
              </.link>
              <button
                id={"delete-page-#{page.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={page.id}
                data-confirm="Delete this page and all sections?"
                class="btn btn-sm btn-ghost text-error"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp seo_description(%Page{seo: seo}) when is_map(seo) do
    case Map.get(seo, "description") do
      value when is_binary(value) and value != "" -> value
      _other -> "No SEO description"
    end
  end

  defp seo_description(_page), do: "No SEO description"

  defp published_label(%Page{published_at: nil}), do: "Not published"

  defp published_label(%Page{published_at: published_at}),
    do: Calendar.strftime(published_at, "%Y-%m-%d")

  defp human_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_status(_), do: "Unknown"

  defp status_class("published"),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp status_class("draft"),
    do:
      "rounded-full bg-sky-500/10 px-2.5 py-1 text-xs font-semibold text-sky-700 dark:text-sky-300"

  defp status_class("archived"),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"

  defp status_class(_),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"
end
