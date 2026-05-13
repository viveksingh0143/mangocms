defmodule MangoCMSWeb.TenantMount do
  @moduledoc "Loads the current tenant into tenant LiveViews."

  import Phoenix.Component, only: [assign: 3]

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.Settings, as: TenantSettings

  def on_mount(:require_tenant, _params, %{"tenant_id" => tenant_id}, socket) do
    tenant = Platform.get_tenant_with_plan!(tenant_id)
    site_settings = TenantSettings.get_or_build_site_settings(tenant)

    {:cont,
     socket
     |> assign(:current_tenant, tenant)
     |> assign(:current_plan, tenant.plan)
     |> assign(:current_tenant_settings, site_settings)}
  rescue
    Ecto.NoResultsError ->
      {:halt, Phoenix.LiveView.redirect(socket, to: "/")}
  end

  def on_mount(:require_tenant, _params, _session, socket) do
    {:halt, Phoenix.LiveView.redirect(socket, to: "/")}
  end
end
