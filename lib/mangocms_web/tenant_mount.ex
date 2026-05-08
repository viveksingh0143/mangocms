defmodule MangoCMSWeb.TenantMount do
  @moduledoc "Loads the current tenant into tenant LiveViews."

  import Phoenix.Component, only: [assign: 3]

  alias MangoCMS.Platform

  def on_mount(:require_tenant, _params, %{"tenant_id" => tenant_id}, socket) do
    tenant = Platform.get_tenant_with_plan!(tenant_id)

    {:cont,
     socket
     |> assign(:current_tenant, tenant)
     |> assign(:current_plan, tenant.plan)}
  rescue
    Ecto.NoResultsError ->
      {:halt, Phoenix.LiveView.redirect(socket, to: "/")}
  end

  def on_mount(:require_tenant, _params, _session, socket) do
    {:halt, Phoenix.LiveView.redirect(socket, to: "/")}
  end
end
