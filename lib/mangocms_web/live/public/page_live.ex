defmodule MangoCMSWeb.Public.PageLive do
  @moduledoc """
  Public tenant page renderer for published content-tree pages.

  Draft and archived pages are never rendered publicly.
  """

  use MangoCMSWeb, :live_view

  alias MangoCMS.Authorization
  alias MangoCMS.Tenant.Pages
  alias MangoCMSWeb.PageRenderer

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tenant = socket.assigns.current_tenant

    case Pages.get_published_page_by_slug(tenant, slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Page not found")
         |> push_navigate(to: "/")}

      page ->
        {:ok,
         assign(socket,
           page: page,
           can_edit_page:
             Authorization.can?(socket.assigns[:current_user], :tenant, :manage_pages)
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />

    <MangoCMSWeb.LandingComponents.landing_navbar
      id="tenant-page-navbar"
      current_user={assigns[:current_user]}
      current_tenant={assigns[:current_tenant]}
      current_tenant_settings={assigns[:current_tenant_settings]}
      platform_registration_enabled={false}
    />

    <main id="public-page" class="bg-base-100 text-base-content">
      <%= if PageRenderer.tree_present?(@page.content_tree) do %>
        <PageRenderer.render_tree tree={@page.content_tree} />
      <% else %>
        <section class="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
          <h1 class="text-4xl font-bold tracking-tight">{@page.title}</h1>
        </section>
      <% end %>
    </main>

    <.link
      :if={@can_edit_page}
      id="public-page-edit-button"
      navigate={~p"/admin/pages/#{@page}/builder"}
      class="btn btn-primary fixed right-6 bottom-6 z-50 shadow-2xl"
    >
      <.icon name="hero-pencil-square" class="size-4" /> Edit page
    </.link>
    """
  end
end
