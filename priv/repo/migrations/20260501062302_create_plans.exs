defmodule MangoCMS.Repo.Migrations.CreatePlans do
  use Ecto.Migration

  def change do
    create table(:plans, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # ── Identity ──────────────────────────────────────────────────────────
      # "starter", "pro", "enterprise"
      add :name, :string, null: false
      # "Starter", "Pro", "Enterprise"
      add :display_name, :string, null: false
      # shown on pricing page
      add :description, :string
      add :active, :boolean, null: false, default: true
      # hidden/internal plans
      add :is_public, :boolean, null: false, default: true

      # ── Pricing ───────────────────────────────────────────────────────────
      # Prices stored in smallest currency unit (paise for INR, cents for USD)
      # e.g. ₹999/mo stored as 99900
      add :price_monthly, :integer, null: false, default: 0
      add :price_yearly, :integer, null: false, default: 0
      add :currency, :string, null: false, default: "INR"

      # Discount when paying yearly, in basis points (e.g. 2000 = 20% off)
      add :yearly_discount_bps, :integer, null: false, default: 0

      # ── Trial ─────────────────────────────────────────────────────────────
      add :trial_period_days, :integer, null: false, default: 0
      add :trial_requires_card, :boolean, null: false, default: false

      # ── Resource Limits ───────────────────────────────────────────────────
      add :max_pages, :integer, null: false, default: 10
      add :max_storage_mb, :integer, null: false, default: 500
      add :max_api_calls_per_day, :integer, null: false, default: 1000
      add :max_users, :integer, null: false, default: 1
      add :max_domains, :integer, null: false, default: 1
      add :max_media_files, :integer, null: false, default: 100

      # ── Feature Flags ─────────────────────────────────────────────────────
      # Flexible key/value map: %{"seo" => true, "analytics" => false, ...}
      add :features, :map, null: false, default: "{}"
      add :custom_domain_support, :boolean, null: false, default: false
      add :api_access, :boolean, null: false, default: false
      add :priority_support, :boolean, null: false, default: false
      add :white_label, :boolean, null: false, default: false

      # ── Sort order on pricing page ─────────────────────────────────────────
      add :sort_order, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:plans, [:name])
    create index(:plans, [:active])
    create index(:plans, [:is_public])
    create index(:plans, [:sort_order])
  end
end
