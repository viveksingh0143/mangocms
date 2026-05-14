defmodule MangoCMS.Tenant.Repo.Migrations.CreateSectionSourcesAndMappings do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:section_sources, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :page_section_id,
          references(:page_sections, type: :binary_id, on_delete: :delete_all),
          null: false

      add :content_type_id, references(:content_types, type: :binary_id, on_delete: :delete_all),
        null: false

      add :status, :string, null: false, default: "published"
      add :filters, :map, null: false, default: %{}
      add :sort, :map, null: false, default: %{}
      add :limit, :integer, null: false, default: 6
      add :offset, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:section_sources, [:page_section_id])
    create_if_not_exists index(:section_sources, [:content_type_id])
    create_if_not_exists index(:section_sources, [:status])

    create_if_not_exists table(:section_mappings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :page_section_id,
          references(:page_sections, type: :binary_id, on_delete: :delete_all),
          null: false

      add :slot, :string, null: false
      add :source_path, :string, null: false
      add :formatter, :string, null: false, default: "text"
      add :settings, :map, null: false, default: %{}
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:section_mappings, [:page_section_id, :slot])
    create_if_not_exists index(:section_mappings, [:page_section_id])
    create_if_not_exists index(:section_mappings, [:slot])
    create_if_not_exists index(:section_mappings, [:formatter])
  end

  def down do
    drop_if_exists index(:section_mappings, [:formatter])
    drop_if_exists index(:section_mappings, [:slot])
    drop_if_exists index(:section_mappings, [:page_section_id])
    drop_if_exists unique_index(:section_mappings, [:page_section_id, :slot])
    drop_if_exists table(:section_mappings)

    drop_if_exists index(:section_sources, [:status])
    drop_if_exists index(:section_sources, [:content_type_id])
    drop_if_exists unique_index(:section_sources, [:page_section_id])
    drop_if_exists table(:section_sources)
  end
end
