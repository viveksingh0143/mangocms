defmodule MangoCMS.Tenant.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :sku, :string
      add :description, :string
      add :status, :string, null: false, default: "draft"
      add :price, :integer, null: false, default: 0
      add :currency, :string, null: false, default: "INR"
      add :stock_quantity, :integer, null: false, default: 0
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:products, [:slug])

    create_if_not_exists unique_index(:products, [:sku], where: "sku IS NOT NULL AND sku <> ''")

    create_if_not_exists index(:products, [:status])
    create_if_not_exists index(:products, [:active])
  end

  def down do
    drop_if_exists index(:products, [:active])
    drop_if_exists index(:products, [:status])
    drop_if_exists unique_index(:products, [:sku])
    drop_if_exists unique_index(:products, [:slug])
    drop_if_exists table(:products)
  end
end
