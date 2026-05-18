defmodule MangoCMSWeb.Tenant.Admin.SettingsLive.Edit do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.Settings, as: TenantSettings
  alias MangoCMSWeb.AdminGuard
  alias MangoCMSWeb.Tenant.Admin.MediaPickerComponent

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_settings) do
      {:ok, socket} ->
        settings = TenantSettings.get_or_create_site_settings!(socket.assigns.current_tenant)

        {:ok,
         socket
         |> assign(:logo_picker, nil)
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

  def handle_event("validate", _params, socket), do: {:noreply, socket}

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

  def handle_event("open_logo_picker", %{"field" => field}, socket)
      when field in ~w(logo_url dark_logo_url) do
    {:noreply, assign(socket, :logo_picker, %{field: field})}
  end

  @impl true
  def handle_info({MediaPickerComponent, {:closed, _context}}, socket) do
    {:noreply, assign(socket, :logo_picker, nil)}
  end

  def handle_info({MediaPickerComponent, {:selected, %{field: field}, asset}}, socket)
      when field in ~w(logo_url dark_logo_url) do
    settings_params = %{field => asset.public_url}

    case TenantSettings.update_site_settings(
           socket.assigns.current_tenant,
           socket.assigns.settings,
           settings_params
         ) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> assign(:logo_picker, nil)
         |> assign(:settings, settings)
         |> assign(:current_tenant_settings, settings)
         |> assign_form(TenantSettings.change_site_settings(settings))
         |> put_flash(:info, "Logo selected from media library.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:logo_picker, nil)
         |> assign_form(changeset)}
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
            <.logo_upload_card
              title="Light theme logo"
              input_label="Light theme logo URL"
              field={@form[:logo_url]}
              field_name="logo_url"
              current_url={@settings.logo_url}
            />
            <.logo_upload_card
              title="Dark theme logo"
              input_label="Dark theme logo URL"
              field={@form[:dark_logo_url]}
              field_name="dark_logo_url"
              current_url={@settings.dark_logo_url}
            />
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

      <.live_component
        :if={@logo_picker}
        module={MediaPickerComponent}
        id="tenant-logo-media-picker"
        tenant={@current_tenant}
        current_user={@current_user}
        kind="image"
        context={@logo_picker}
      />
    </Layouts.tenant_admin>
    """
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  attr :title, :string, required: true
  attr :input_label, :string, required: true
  attr :field, Phoenix.HTML.FormField, required: true
  attr :field_name, :string, required: true
  attr :current_url, :string, default: nil

  defp logo_upload_card(assigns) do
    ~H"""
    <div class="rounded-lg border border-base-300 bg-base-200/40 p-4">
      <div class="flex items-start justify-between gap-4">
        <div>
          <h3 class="text-sm font-semibold text-base-content">{@title}</h3>
          <p class="mt-1 text-xs text-base-content/60">
            Upload a tenant-scoped logo or keep using an external URL.
          </p>
        </div>
        <div class="flex size-16 items-center justify-center overflow-hidden rounded-md border border-base-300 bg-base-100">
          <img
            :if={present?(@current_url)}
            src={@current_url}
            alt=""
            class="max-h-full max-w-full object-contain"
          />
          <.icon :if={!present?(@current_url)} name="hero-photo" class="size-6 text-base-content/35" />
        </div>
      </div>

      <div class="mt-4 space-y-3">
        <.input field={@field} type="text" label={@input_label} />
        <button
          id={"pick-#{@field_name}-button"}
          type="button"
          phx-click="open_logo_picker"
          phx-value-field={@field_name}
          class="btn btn-outline btn-sm w-full"
        >
          <.icon name="hero-photo" class="size-4" /> Choose from media library
        </button>
      </div>
    </div>
    """
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_value), do: false
end
