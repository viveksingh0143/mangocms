defmodule MangoCMS.Repo.Migrations.CreateTenants do
  use Ecto.Migration

  # Tenant status values:
  #   "trialing"   — on free trial, trial_ends_at is set
  #   "active"     — paid subscription, current_period_end is set
  #   "past_due"   — payment failed, grace period
  #   "cancelled"  — subscription cancelled, access until period_end
  #   "suspended"  — admin-suspended, no access

  def change do
    create table(:tenants, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # ── Identity ──────────────────────────────────────────────────────────
      add :name, :string, null: false
      # custom domain: "myblog.com"
      add :domain, :string, null: false
      # platform subdomain: "myblog" → myblog.mangocms.com
      add :subdomain, :string, null: false
      # used for /data/tenants/{slug}/ on disk
      add :slug, :string, null: false
      add :active, :boolean, null: false, default: true

      # ── Plan attachment (FK → plans.id) ───────────────────────────────────
      # Using references/2 — this is the correct Ecto.Migration way to
      # declare a foreign key. NOT create_constraint/3 (that function does not exist).
      add :plan_id, references(:plans, type: :binary_id, on_delete: :restrict), null: false

      # ── Subscription status ───────────────────────────────────────────────
      add :status, :string, null: false, default: "trialing"
      # values: "trialing" | "active" | "past_due" | "cancelled" | "suspended"

      # ── Subscription billing cycle ─────────────────────────────────────────
      # "monthly" | "yearly" | nil (trial/free)
      add :billing_cycle, :string
      add :current_period_start, :utc_datetime
      add :current_period_end, :utc_datetime

      # ── Trial details ─────────────────────────────────────────────────────
      add :trial_started_at, :utc_datetime
      add :trial_ends_at, :utc_datetime
      add :trial_used, :boolean, null: false, default: false
      # trial_used prevents re-using trial on the same account across plan changes

      # ── Cancellation ──────────────────────────────────────────────────────
      add :cancelled_at, :utc_datetime
      add :cancellation_reason, :string
      # access_until = current_period_end at cancellation time (no separate field needed)

      # ── Suspension ────────────────────────────────────────────────────────
      add :suspended_at, :utc_datetime
      add :suspension_reason, :string

      # ── Payment / external billing reference ──────────────────────────────
      # Store your payment gateway's subscription ID here
      # (Razorpay, Stripe, etc.) — no card data ever stored here
      add :external_subscription_id, :string
      add :external_customer_id, :string

      # ── Storage paths (set automatically from slug) ────────────────────────
      # "data/tenants/{slug}/tenant.db"
      add :db_path, :string
      # "data/tenants/{slug}/media/"
      add :storage_path, :string

      timestamps(type: :utc_datetime)
    end

    # Indexes for fast domain resolution (critical hot path)
    create unique_index(:tenants, [:domain])
    create unique_index(:tenants, [:subdomain])
    create unique_index(:tenants, [:slug])

    # Subscription management queries
    create index(:tenants, [:plan_id])
    create index(:tenants, [:status])
    create index(:tenants, [:trial_ends_at])
    create index(:tenants, [:current_period_end])
    create index(:tenants, [:external_subscription_id])
  end
end
