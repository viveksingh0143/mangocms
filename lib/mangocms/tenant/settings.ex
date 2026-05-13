defmodule MangoCMS.Tenant.Settings do
  @moduledoc "Tenant-local website settings used by tenant public and admin UI."

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.RepoManager, as: TenantRepoManager
  alias MangoCMS.Tenant.Settings.SiteSettings

  def get_site_settings(%Tenant{} = tenant) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get(SiteSettings, SiteSettings.fixed_id())
    end)
  rescue
    _ -> nil
  end

  def get_or_build_site_settings(%Tenant{} = tenant) do
    get_site_settings(tenant) || build_default_site_settings(tenant)
  end

  def get_or_create_site_settings!(%Tenant{} = tenant) do
    case get_site_settings(tenant) do
      %SiteSettings{} = settings ->
        settings

      nil ->
        attrs = SiteSettings.default_attrs(tenant.name)

        TenantRepoManager.with_repo(tenant, fn repo ->
          %SiteSettings{}
          |> SiteSettings.changeset(attrs)
          |> repo.insert!()
        end)
    end
  end

  def change_site_settings(%SiteSettings{} = settings, attrs \\ %{}) do
    SiteSettings.changeset(settings, attrs)
  end

  def update_site_settings(%Tenant{} = tenant, %SiteSettings{} = settings, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      settings
      |> SiteSettings.changeset(attrs)
      |> repo.insert_or_update()
    end)
  end

  def site_name(%SiteSettings{site_name: site_name}, %Tenant{} = tenant)
      when is_binary(site_name) do
    case String.trim(site_name) do
      "" -> tenant.name
      name -> name
    end
  end

  def site_name(_settings, %Tenant{} = tenant), do: tenant.name

  def logo_url(%SiteSettings{logo_url: logo_url}), do: present_url(logo_url)
  def logo_url(_settings), do: nil

  def dark_logo_url(%SiteSettings{dark_logo_url: dark_logo_url}), do: present_url(dark_logo_url)
  def dark_logo_url(_settings), do: nil

  defp build_default_site_settings(%Tenant{} = tenant) do
    %SiteSettings{}
    |> SiteSettings.changeset(SiteSettings.default_attrs(tenant.name))
    |> Ecto.Changeset.apply_changes()
  end

  defp present_url(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      url -> url
    end
  end

  defp present_url(_value), do: nil
end
