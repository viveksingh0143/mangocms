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
      add :content_tree, {:array, :map}, null: false, default: []
      add :content_tree_version, :integer, null: false, default: 1

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:pages, [:slug])
    create_if_not_exists index(:pages, [:type])
    create_if_not_exists index(:pages, [:status])
    create_if_not_exists index(:pages, [:published_at])

    create_if_not_exists table(:global_sections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :content_tree, {:array, :map}, null: false, default: []

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:global_sections, [:name])

    create_if_not_exists table(:page_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :page_id, references(:pages, type: :binary_id, on_delete: :delete_all), null: false
      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :content_tree, {:array, :map}, null: false
      add :version_number, :integer, null: false
      add :label, :string
      add :change_summary, :string
      add :snapshot_type, :string, null: false, default: "auto"
      add :restored_from, :integer

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create_if_not_exists unique_index(:page_versions, [:page_id, :version_number])
    create_if_not_exists index(:page_versions, [:page_id, :snapshot_type])
    create_if_not_exists index(:page_versions, [:created_by_id])

    create_if_not_exists table(:global_section_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :global_section_id,
          references(:global_sections, type: :binary_id, on_delete: :delete_all),
          null: false

      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :content_tree, {:array, :map}, null: false
      add :version_number, :integer, null: false
      add :label, :string
      add :change_summary, :string
      add :snapshot_type, :string, null: false, default: "auto"
      add :restored_from, :integer

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create_if_not_exists unique_index(:global_section_versions, [
                           :global_section_id,
                           :version_number
                         ])

    create_if_not_exists index(:global_section_versions, [:global_section_id, :snapshot_type])
    create_if_not_exists index(:global_section_versions, [:created_by_id])

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

    drop_if_exists index(:page_sections, [:mode])
    drop_if_exists index(:page_sections, [:type])
    drop_if_exists index(:page_sections, [:page_id, :position])
    drop_if_exists index(:page_sections, [:page_id])
    drop_if_exists table(:page_sections)

    drop_if_exists index(:global_section_versions, [:created_by_id])
    drop_if_exists index(:global_section_versions, [:global_section_id, :snapshot_type])
    drop_if_exists unique_index(:global_section_versions, [:global_section_id, :version_number])
    drop_if_exists table(:global_section_versions)

    drop_if_exists index(:page_versions, [:created_by_id])
    drop_if_exists index(:page_versions, [:page_id, :snapshot_type])
    drop_if_exists unique_index(:page_versions, [:page_id, :version_number])
    drop_if_exists table(:page_versions)

    drop_if_exists unique_index(:global_sections, [:name])
    drop_if_exists table(:global_sections)

    drop_if_exists index(:pages, [:published_at])
    drop_if_exists index(:pages, [:status])
    drop_if_exists index(:pages, [:type])
    drop_if_exists unique_index(:pages, [:slug])
    drop_if_exists table(:pages)
  end
end
