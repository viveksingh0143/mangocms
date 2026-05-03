defmodule MangoCMS.Platform.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @valid_currencies ~w(INR USD EUR GBP AUD SGD)
  @required_fields ~w(name display_name price_monthly price_yearly currency)a
  @optional_fields ~w(
    description
    active
    is_public
    yearly_discount_bps
    trial_period_days
    trial_requires_card
    max_pages
    max_storage_mb
    max_api_calls_per_day
    max_users
    max_domains
    max_media_files
    features
    custom_domain_support
    api_access
    priority_support
    white_label
    sort_order
  )a

  schema "plans" do
    # ── Identity ────────────────────────────────────────────────
    field :name, :string
    field :display_name, :string
    field :description, :string
    field :active, :boolean, default: true
    field :is_public, :boolean, default: true

    # ── Pricing ─────────────────────────────────────────────────
    # Stored in smallest unit: paise (INR) or cents (USD)
    # ₹999/mo → 99900 | $9.99/mo → 999
    field :price_monthly, :integer, default: 0
    field :price_yearly, :integer, default: 0
    field :currency, :string, default: "INR"
    field :yearly_discount_bps, :integer, default: 0

    # ── Trial ───────────────────────────────────────────────────
    field :trial_period_days, :integer, default: 0
    field :trial_requires_card, :boolean, default: false

    # ── Resource limits ──────────────────────────────────────────
    field :max_pages, :integer, default: 10
    field :max_storage_mb, :integer, default: 500
    field :max_api_calls_per_day, :integer, default: 1000
    field :max_users, :integer, default: 1
    field :max_domains, :integer, default: 1
    field :max_media_files, :integer, default: 100

    # ── Feature flags ────────────────────────────────────────────
    # %{"seo" => true, "analytics" => false, "exports" => true}
    field :features, :map, default: %{}
    field :custom_domain_support, :boolean, default: false
    field :api_access, :boolean, default: false
    field :priority_support, :boolean, default: false
    field :white_label, :boolean, default: false

    # ── Display ──────────────────────────────────────────────────
    field :sort_order, :integer, default: 0

    has_many :tenants, MangoCMS.Platform.Tenant

    timestamps()
  end

  # ── Changesets ───────────────────────────────────────────────

  def changeset(plan, attrs) do
    plan
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:display_name, min: 2, max: 100)
    |> validate_inclusion(:currency, @valid_currencies)
    |> validate_number(:price_monthly, greater_than_or_equal_to: 0)
    |> validate_number(:price_yearly, greater_than_or_equal_to: 0)
    |> validate_number(:yearly_discount_bps,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 10_000
    )
    |> validate_number(:trial_period_days, greater_than_or_equal_to: 0)
    |> validate_number(:max_pages, greater_than: 0)
    |> validate_number(:max_storage_mb, greater_than: 0)
    |> validate_number(:max_api_calls_per_day, greater_than: 0)
    |> validate_number(:max_users, greater_than: 0)
    |> validate_number(:max_domains, greater_than: 0)
    |> validate_number(:max_media_files, greater_than: 0)
    |> validate_number(:sort_order, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
    |> normalize_name()
  end

  # ── Virtual helpers (not persisted) ─────────────────────────

  @doc "Monthly price as a float. e.g. 99900 → 999.0"
  def monthly_price_float(%__MODULE__{price_monthly: p, currency: c}),
    do: to_major_unit(p, c)

  @doc "Yearly price as a float."
  def yearly_price_float(%__MODULE__{price_yearly: p, currency: c}),
    do: to_major_unit(p, c)

  @doc "Yearly discount as a percentage float. e.g. 2000 bps → 20.0"
  def yearly_discount_percent(%__MODULE__{yearly_discount_bps: bps}),
    do: bps / 100.0

  @doc "True if this plan has a free trial."
  def has_trial?(%__MODULE__{trial_period_days: days}), do: days > 0

  @doc "Check if a feature key is enabled on this plan."
  def feature_enabled?(%__MODULE__{features: features}, key) when is_binary(key),
    do: Map.get(features || %{}, key, false)

  # ── Private ──────────────────────────────────────────────────

  # Force name to lowercase + underscored for consistency
  defp normalize_name(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        normalized = name |> String.downcase() |> String.replace(~r/\s+/, "_")
        put_change(changeset, :name, normalized)
    end
  end

  # INR has 2 decimal places (paise), same as USD cents
  defp to_major_unit(amount, _currency), do: amount / 100.0
end
