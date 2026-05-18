defmodule MangoCMS.Tenant.Repo.Migrations.CreateTenantMediaAssets do
  use Ecto.Migration

  def change do
    create table(:media_assets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :original_filename, :string, null: false
      add :stored_filename, :string, null: false
      add :mime_type, :string, null: false
      add :file_ext, :string, null: false
      add :file_size, :integer, null: false, default: 0
      add :storage_path, :string, null: false
      add :public_url, :string, null: false
      add :alt_text, :string
      add :title, :string
      add :description, :string
      add :folder, :string
      add :kind, :string, null: false, default: "image"
      add :width, :integer
      add :height, :integer
      add :metadata, :map, null: false, default: %{}
      add :uploaded_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:media_assets, [:kind])
    create index(:media_assets, [:folder])
    create index(:media_assets, [:uploaded_by_id])
    create index(:media_assets, [:inserted_at])
    create unique_index(:media_assets, [:public_url])
  end
end
