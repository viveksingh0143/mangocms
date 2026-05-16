defmodule MangoCMS.Tenant.Repo.Migrations.CreateSections do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:sections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :template_key, :string, null: false, default: "custom"
      add :group_label, :string, null: false, default: "General"
      add :mode, :string, null: false, default: "static"
      add :settings, :map, null: false, default: %{}
      add :source_config, :map, null: false, default: %{}
      add :filters, :map, null: false, default: %{}
      add :loop_settings, :map, null: false, default: %{"enabled" => false, "limit" => 6}
      add :content_tree, {:array, :map}, null: false, default: []

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:sections, [:name])
    create_if_not_exists index(:sections, [:template_key])
    create_if_not_exists index(:sections, [:group_label])
    create_if_not_exists index(:sections, [:mode])

    create_if_not_exists table(:section_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :section_id, references(:sections, type: :binary_id, on_delete: :delete_all),
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

    create_if_not_exists unique_index(:section_versions, [:section_id, :version_number])
    create_if_not_exists index(:section_versions, [:section_id, :snapshot_type])
    create_if_not_exists index(:section_versions, [:created_by_id])
  end

  def down do
    drop_if_exists index(:section_versions, [:created_by_id])
    drop_if_exists index(:section_versions, [:section_id, :snapshot_type])
    drop_if_exists unique_index(:section_versions, [:section_id, :version_number])
    drop_if_exists table(:section_versions)

    drop_if_exists index(:sections, [:mode])
    drop_if_exists index(:sections, [:group_label])
    drop_if_exists index(:sections, [:template_key])
    drop_if_exists unique_index(:sections, [:name])
    drop_if_exists table(:sections)
  end
end
