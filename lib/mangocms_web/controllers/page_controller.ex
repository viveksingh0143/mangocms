defmodule MangoCMSWeb.PageController do
  use MangoCMSWeb, :controller

  alias MangoCMSWeb.PlatformRegistration

  def home(conn, _params) do
    render(conn, :home,
      platform_registration_enabled: PlatformRegistration.enabled?(),
      platform_cta_path: ~p"/platform/register",
      platform_cta_label: "Create your website"
    )
  end
end
