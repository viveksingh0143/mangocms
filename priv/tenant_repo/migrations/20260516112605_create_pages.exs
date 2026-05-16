defmodule MangoCMS.Tenant.Repo.Migrations.CreatePages do
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
  end

  def down do
    drop_if_exists index(:page_versions, [:created_by_id])
    drop_if_exists index(:page_versions, [:page_id, :snapshot_type])
    drop_if_exists unique_index(:page_versions, [:page_id, :version_number])
    drop_if_exists table(:page_versions)

    drop_if_exists index(:pages, [:published_at])
    drop_if_exists index(:pages, [:status])
    drop_if_exists index(:pages, [:type])
    drop_if_exists unique_index(:pages, [:slug])
    drop_if_exists table(:pages)
  end
end
