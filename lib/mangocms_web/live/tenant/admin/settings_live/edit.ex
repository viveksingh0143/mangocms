defmodule MangoCMSWeb.Tenant.Admin.SettingsLive.Edit do
  use MangoCMSWeb, :live_view

  alias MangoCMS.TenantSettings
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_settings) do
      {:ok, socket} ->
        settings = TenantSettings.get_or_create_site_settings!(socket.assigns.current_tenant)

        {:ok,
         socket
         |> assign(:settings, settings)
         |> assign(:current_tenant_settings, settings)
         |> assign_form(TenantSettings.change_site_settings(settings))}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"site_settings" => settings_params}, socket) do
    changeset =
      socket.assigns.settings
      |> TenantSettings.change_site_settings(settings_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"site_settings" => settings_params}, socket) do
    case TenantSettings.update_site_settings(
           socket.assigns.current_tenant,
           socket.assigns.settings,
           settings_params
         ) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tenant settings updated successfully.")
         |> assign(:settings, settings)
         |> assign(:current_tenant_settings, settings)
         |> assign_form(TenantSettings.change_site_settings(settings))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title="Tenant settings"
      subtitle="Control the website name, logos, support contact, locale, and timezone for this tenant."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:settings}
    >
      <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
        <.header>
          Website basics
          <:subtitle>
            These values are stored in the tenant database and reflected in tenant UI.
          </:subtitle>
        </.header>

        <.form for={@form} id="tenant-settings-form" phx-change="validate" phx-submit="save">
          <div class="grid gap-5 md:grid-cols-2">
            <.input field={@form[:site_name]} type="text" label="Website name" />
            <.input field={@form[:tagline]} type="text" label="Tagline" />
          </div>

          <div class="grid gap-5 md:grid-cols-2">
            <.input field={@form[:logo_url]} type="url" label="Light theme logo URL" />
            <.input field={@form[:dark_logo_url]} type="url" label="Dark theme logo URL" />
          </div>

          <div class="grid gap-5 md:grid-cols-3">
            <.input field={@form[:support_email]} type="email" label="Support email" />
            <.input field={@form[:locale]} type="text" label="Locale" placeholder="en" />
            <.input field={@form[:timezone]} type="text" label="Timezone" placeholder="UTC" />
          </div>

          <div class="mt-6 flex items-center justify-end gap-3">
            <.button
              id="tenant-settings-dashboard-button"
              navigate={~p"/admin/dashboard"}
              class="btn btn-ghost"
            >
              Back
            </.button>
            <.button id="save-tenant-settings-button" variant="primary" phx-disable-with="Saving...">
              Save settings
            </.button>
          </div>
        </.form>
      </section>
    </Layouts.tenant_admin>
    """
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
