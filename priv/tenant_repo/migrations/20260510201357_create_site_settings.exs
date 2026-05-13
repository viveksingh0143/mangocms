defmodule MangoCMS.TenantRepo.Migrations.CreateSiteSettings do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:site_settings, primary_key: false) do
      add :id, :string, primary_key: true
      add :site_name, :string, null: false
      add :tagline, :string
      add :logo_url, :string
      add :dark_logo_url, :string
      add :support_email, :string
      add :locale, :string, null: false, default: "en"
      add :timezone, :string, null: false, default: "UTC"

      timestamps(type: :utc_datetime)
    end
  end

  def down do
    drop_if_exists table(:site_settings)
  end
end
