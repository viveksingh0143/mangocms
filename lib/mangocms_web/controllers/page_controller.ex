defmodule MangoCMSWeb.PageController do
  use MangoCMSWeb, :controller

  alias MangoCMS.Authorization
  alias MangoCMS.Tenant.Pages
  alias MangoCMSWeb.PlatformRegistration

  def home(conn, _params) do
    render(conn, :home,
      platform_registration_enabled: PlatformRegistration.enabled?(),
      platform_cta_path: ~p"/platform/register",
      platform_cta_label: "Create your website"
    )
  end

  def show(conn, %{"slug" => slug}) do
    tenant = conn.assigns.current_tenant

    case Pages.get_published_page_by_slug(tenant, slug) do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("Page not found")

      page ->
        render(conn, :show,
          page: page,
          sections: page.sections,
          section_items: Pages.section_render_items(tenant, page.sections),
          can_edit_page: Authorization.can?(conn.assigns[:current_user], :tenant, :manage_pages)
        )
    end
  end
end
