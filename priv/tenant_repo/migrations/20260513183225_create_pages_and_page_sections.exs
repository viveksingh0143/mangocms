defmodule MangoCMS.Tenant.Repo.Migrations.CreatePagesAndPageSections do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:pages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :type, :string, null: false, default: "page"
      add :status, :string, null: false, default: "draft"
      add :seo, :map, null: false, default: %{}
      add :published_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:pages, [:slug])
    create_if_not_exists index(:pages, [:type])
    create_if_not_exists index(:pages, [:status])
    create_if_not_exists index(:pages, [:published_at])

    create_if_not_exists table(:page_sections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :page_id, references(:pages, type: :binary_id, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :template_id, :string, null: false, default: "default"
      add :mode, :string, null: false, default: "fixed"
      add :fixed_data, :map, null: false, default: %{}
      add :settings, :map, null: false, default: %{}
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:page_sections, [:page_id])
    create_if_not_exists index(:page_sections, [:page_id, :position])
    create_if_not_exists index(:page_sections, [:type])
    create_if_not_exists index(:page_sections, [:mode])
  end

  def down do
    drop_if_exists index(:page_sections, [:mode])
    drop_if_exists index(:page_sections, [:type])
    drop_if_exists index(:page_sections, [:page_id, :position])
    drop_if_exists index(:page_sections, [:page_id])
    drop_if_exists table(:page_sections)

    drop_if_exists index(:pages, [:published_at])
    drop_if_exists index(:pages, [:status])
    drop_if_exists index(:pages, [:type])
    drop_if_exists unique_index(:pages, [:slug])
    drop_if_exists table(:pages)
  end
end
