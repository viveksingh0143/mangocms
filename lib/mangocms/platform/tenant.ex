defmodule MangoCMS.Platform.Tenant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @valid_statuses ~w(trialing active past_due cancelled suspended)
  @valid_billing ~w(monthly yearly)

  @required_fields ~w(name domain subdomain slug plan_id)a
  @optional_fields ~w(
    active
    status
    billing_cycle
    current_period_start
    current_period_end
    trial_started_at
    trial_ends_at
    trial_used
    cancelled_at
    cancellation_reason
    suspended_at
    suspension_reason
    external_subscription_id
    external_customer_id
    db_path
    storage_path
  )a

  schema "tenants" do
    # ── Identity ─────────────────────────────────────────────────
    field :name, :string
    # "myblog.com"
    field :domain, :string
    # "myblog" → myblog.mangocms.com
    field :subdomain, :string
    # disk key → data/tenants/{slug}/
    field :slug, :string
    field :active, :boolean, default: true

    # ── Plan (FK) ────────────────────────────────────────────────
    belongs_to :plan, MangoCMS.Platform.Plan

    # ── Subscription status ──────────────────────────────────────
    # "trialing" | "active" | "past_due" | "cancelled" | "suspended"
    field :status, :string, default: "trialing"

    # ── Billing cycle ────────────────────────────────────────────
    # "monthly" | "yearly"
    field :billing_cycle, :string
    field :current_period_start, :utc_datetime
    field :current_period_end, :utc_datetime

    # ── Trial ────────────────────────────────────────────────────
    field :trial_started_at, :utc_datetime
    field :trial_ends_at, :utc_datetime
    field :trial_used, :boolean, default: false

    # ── Cancellation ─────────────────────────────────────────────
    field :cancelled_at, :utc_datetime
    field :cancellation_reason, :string

    # ── Suspension ───────────────────────────────────────────────
    field :suspended_at, :utc_datetime
    field :suspension_reason, :string

    # ── External billing refs (Razorpay / Stripe) ────────────────
    field :external_subscription_id, :string
    field :external_customer_id, :string

    # ── Storage paths ────────────────────────────────────────────
    # "data/tenants/{slug}/tenant.db"
    field :db_path, :string
    # "data/tenants/{slug}/media/"
    field :storage_path, :string

    timestamps()
  end

  # ══════════════════════════════════════════════════════════════
  # CHANGESETS
  # ══════════════════════════════════════════════════════════════

  @doc "Used when creating a new tenant — derives paths from slug automatically."
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 2, max: 100)
    |> validate_format(:domain, ~r/^[a-z0-9.-]+\.[a-z]{2,}$/,
      message: "must be a valid domain like myblog.com"
    )
    |> validate_format(:subdomain, ~r/^[a-z0-9-]+$/,
      message: "only lowercase letters, numbers and hyphens"
    )
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/,
      message: "only lowercase letters, numbers, underscores and hyphens"
    )
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_billing_cycle()
    |> unique_constraint(:domain)
    |> unique_constraint(:subdomain)
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:plan_id)
    |> put_storage_paths()
  end

  @doc "Used when activating a paid subscription."
  def subscription_changeset(tenant, attrs) do
    tenant
    |> cast(attrs, ~w(status billing_cycle current_period_start current_period_end)a)
    |> validate_required(~w(status billing_cycle current_period_start current_period_end)a)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:billing_cycle, @valid_billing)
  end

  @doc "Used when starting a trial."
  def trial_changeset(tenant, attrs) do
    tenant
    |> cast(attrs, ~w(status trial_started_at trial_ends_at trial_used)a)
    |> validate_required(~w(status trial_started_at trial_ends_at)a)
    |> validate_inclusion(:status, ["trialing"])
    |> validate_trial_not_reused()
  end

  @doc "Used when cancelling."
  def cancellation_changeset(tenant, attrs) do
    tenant
    |> cast(attrs, ~w(status cancelled_at cancellation_reason)a)
    |> validate_required(~w(status cancelled_at)a)
    |> validate_inclusion(:status, ["cancelled"])
  end

  @doc "Used when suspending."
  def suspension_changeset(tenant, attrs) do
    tenant
    |> cast(attrs, ~w(status active suspended_at suspension_reason)a)
    |> validate_required(~w(status suspended_at)a)
    |> validate_inclusion(:status, ["suspended"])
  end

  # ══════════════════════════════════════════════════════════════
  # VIRTUAL HELPERS
  # ══════════════════════════════════════════════════════════════

  @doc "True if tenant is on active trial and it hasn't expired."
  def on_active_trial?(%__MODULE__{status: "trialing", trial_ends_at: nil}), do: false

  def on_active_trial?(%__MODULE__{status: "trialing", trial_ends_at: ends_at}) do
    DateTime.compare(DateTime.utc_now(), ends_at) == :lt
  end

  def on_active_trial?(_), do: false

  @doc "True if trial period has ended."
  def trial_expired?(%__MODULE__{status: "trialing", trial_ends_at: nil}), do: false

  def trial_expired?(%__MODULE__{status: "trialing", trial_ends_at: ends_at}) do
    DateTime.compare(DateTime.utc_now(), ends_at) == :gt
  end

  def trial_expired?(_), do: false

  @doc "True if tenant has access (active, trialing, or past_due grace period)."
  def has_access?(%__MODULE__{status: status}) do
    status in ~w(active trialing past_due)
  end

  @doc "Days remaining in trial. Returns nil if not on trial."
  def trial_days_remaining(%__MODULE__{status: "trialing", trial_ends_at: ends_at})
      when not is_nil(ends_at) do
    diff = DateTime.diff(ends_at, DateTime.utc_now(), :second)
    max(0, div(diff, 86_400))
  end

  def trial_days_remaining(_), do: nil

  # ══════════════════════════════════════════════════════════════
  # PRIVATE
  # ══════════════════════════════════════════════════════════════

  # Auto-derive db_path and storage_path from slug
  defp put_storage_paths(changeset) do
    case get_field(changeset, :slug) do
      nil ->
        changeset

      slug ->
        root = Application.get_env(:mangocms, :tenant_data_root, "data/tenants")

        changeset
        |> put_change(:db_path, "#{root}/#{slug}/tenant.db")
        |> put_change(:storage_path, "#{root}/#{slug}/media/")
    end
  end

  defp validate_billing_cycle(changeset) do
    case get_field(changeset, :billing_cycle) do
      nil -> changeset
      _cycle -> validate_inclusion(changeset, :billing_cycle, @valid_billing)
    end
  end

  defp validate_trial_not_reused(changeset) do
    # Prevents a tenant from starting a second trial
    if get_field(changeset, :trial_used) == true do
      add_error(changeset, :trial_used, "trial has already been used for this account")
    else
      changeset
    end
  end
end
