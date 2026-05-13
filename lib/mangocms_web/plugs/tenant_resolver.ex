defmodule MangoCMSWeb.Plugs.TenantResolver do
  @moduledoc """
  Resolves the current tenant from the request host and stores it in the request context.
  """

  import Plug.Conn

  alias MangoCMS.Platform
  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.Settings, as: TenantSettings

  def init(opts), do: opts

  def call(conn, _opts) do
    case Platform.resolve_tenant_from_host(conn.host) do
      %Tenant{} = tenant ->
        site_settings = TenantSettings.get_or_build_site_settings(tenant)

        conn
        |> assign(:current_tenant, tenant)
        |> assign(:current_plan, tenant.plan)
        |> assign(:current_tenant_settings, site_settings)
        |> put_private(:mangocms_tenant, tenant)
        |> put_session(:tenant_id, tenant.id)

      nil ->
        conn
        |> assign(:current_tenant, nil)
        |> assign(:current_plan, nil)
        |> assign(:current_tenant_settings, nil)
        |> delete_session(:tenant_id)
    end
  end

  @doc "Adds tenant identity to LiveView session data."
  def live_session(conn) do
    case conn.assigns[:current_tenant] do
      %Tenant{id: tenant_id} -> %{"tenant_id" => tenant_id}
      _ -> %{}
    end
  end
end
