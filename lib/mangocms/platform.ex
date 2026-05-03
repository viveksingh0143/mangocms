defmodule MangoCMS.Platform do
  @moduledoc """
  The Platform context.

  Single entry point for all Plan and Tenant operations.
  Nothing outside this module should call Repo directly.

  ## Tenant subscription lifecycle

      new tenant
          │
          ▼
      trialing  ──(trial ends)──► past_due
          │                           │
          │(payment)                  │(payment)
          ▼                           ▼
        active ◄────────────────────────
          │
          ├──(payment fails)──► past_due
          ├──(cancel)─────────► cancelled
          └──(admin)──────────► suspended
  """

  import Ecto.Query

  alias MangoCMS.Repo
  alias MangoCMS.Platform.{Plan, Tenant}

  require Logger

  # ═══════════════════════════════════════════════════════════════
  # PLANS
  # ═══════════════════════════════════════════════════════════════

  @doc "Returns all plans with no filtering."
  @spec list_plans() :: [Plan.t()]
  def list_plans, do: Repo.all(Plan)

  @doc "Returns only active, publicly visible plans ordered by `sort_order`."
  @spec list_active_plans() :: [Plan.t()]
  def list_active_plans do
    Plan
    |> where([p], p.active == true and p.is_public == true)
    |> order_by([p], asc: p.sort_order)
    |> Repo.all()
  end

  @doc "Returns a plan by id, or `nil` if not found."
  @spec get_plan(binary()) :: Plan.t() | nil
  def get_plan(id), do: Repo.get(Plan, id)

  @doc "Returns a plan by id. Raises `Ecto.NoResultsError` if not found."
  @spec get_plan!(binary()) :: Plan.t()
  def get_plan!(id), do: Repo.get!(Plan, id)

  @doc "Returns a plan by slug name (e.g. `\"pro\"`), or `nil`."
  @spec get_plan_by_name(String.t()) :: Plan.t() | nil
  def get_plan_by_name(name), do: Repo.get_by(Plan, name: name)

  @doc "Creates a plan. Returns `{:ok, plan}` or `{:error, changeset}`."
  @spec create_plan(map()) :: {:ok, Plan.t()} | {:error, Ecto.Changeset.t()}
  def create_plan(attrs) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Updates a plan. Returns `{:ok, plan}` or `{:error, changeset}`."
  @spec update_plan(Plan.t(), map()) :: {:ok, Plan.t()} | {:error, Ecto.Changeset.t()}
  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  @doc "Returns a changeset for tracking plan changes."
  @spec change_plan_changeset(Plan.t(), map()) :: Ecto.Changeset.t()
  def change_plan_changeset(%Plan{} = plan, attrs \\ %{}) do
    Plan.changeset(plan, attrs)
  end

  @doc """
  Deletes a plan.

  > #### Warning {: .warning}
  > Fails with a foreign key constraint if any tenants are currently
  > on this plan (`on_delete: :restrict` in migration).
  > Check for tenants before calling this.
  """
  @spec delete_plan(Plan.t()) :: {:ok, Plan.t()} | {:error, Ecto.Changeset.t()}
  def delete_plan(%Plan{} = plan), do: Repo.delete(plan)

  # ═══════════════════════════════════════════════════════════════
  # TENANTS
  # ═══════════════════════════════════════════════════════════════

  @doc "Returns all tenants with no preloads."
  @spec list_tenants() :: [Tenant.t()]
  def list_tenants, do: Repo.all(Tenant)

  @doc "Returns all tenants with `:plan` preloaded in a single query."
  @spec list_tenants_with_plan() :: [Tenant.t()]
  def list_tenants_with_plan do
    Tenant
    |> preload(:plan)
    |> Repo.all()
  end

  @doc "Returns tenants filtered by subscription status string."
  @spec list_tenants_by_status(String.t()) :: [Tenant.t()]
  def list_tenants_by_status(status) do
    Tenant
    |> where([t], t.status == ^status)
    |> Repo.all()
  end

  @doc "Returns all trialing tenants whose trial ended before now. Used by Oban workers."
  @spec list_expired_trials() :: [Tenant.t()]
  def list_expired_trials do
    now = DateTime.utc_now()

    Tenant
    |> where([t], t.status == "trialing" and t.trial_ends_at < ^now)
    |> Repo.all()
  end

  @doc "Returns all active tenants whose billing period ended before now. Used by Oban workers."
  @spec list_expired_subscriptions() :: [Tenant.t()]
  def list_expired_subscriptions do
    now = DateTime.utc_now()

    Tenant
    |> where([t], t.status == "active" and t.current_period_end < ^now)
    |> Repo.all()
  end

  @doc "Returns a tenant by id, or `nil` if not found."
  @spec get_tenant(binary()) :: Tenant.t() | nil
  def get_tenant(id), do: Repo.get(Tenant, id)

  @doc "Returns a tenant by id. Raises `Ecto.NoResultsError` if not found."
  @spec get_tenant!(binary()) :: Tenant.t()
  def get_tenant!(id), do: Repo.get!(Tenant, id)

  @doc "Returns a tenant with `:plan` preloaded. Raises if not found."
  @spec get_tenant_with_plan!(binary()) :: Tenant.t()
  def get_tenant_with_plan!(id) do
    Tenant
    |> preload(:plan)
    |> Repo.get!(id)
  end

  @doc """
  Resolves an active tenant by domain name. Returns `nil` if not found.
  Used by `TenantResolverPlug` as the DB fallback after a Redis miss.
  """
  @spec get_tenant_by_domain(String.t()) :: Tenant.t() | nil
  def get_tenant_by_domain(domain) do
    Tenant
    |> where([t], t.domain == ^domain and t.active == true)
    |> Repo.one()
  end

  @doc """
  Resolves an active tenant by domain with `:plan` preloaded in a single query.
  This is the critical hot path — used by `TenantResolverPlug` to populate Redis.
  """
  @spec get_tenant_by_domain_with_plan(String.t()) :: Tenant.t() | nil
  def get_tenant_by_domain_with_plan(domain) do
    Tenant
    |> where([t], t.domain == ^domain and t.active == true)
    |> preload(:plan)
    |> Repo.one()
  end

  @doc """
  Creates a tenant and provisions its media storage directory on disk.

  ## Side effects
  Creates `data/tenants/{slug}/media/` on the local filesystem.
  The path is derived automatically from the slug in `Tenant.changeset/2`.
  A storage provisioning failure is non-fatal — the DB record is retained
  and the directory can be recreated later without data loss.
  """
  @spec create_tenant(map()) :: {:ok, Tenant.t()} | {:error, Ecto.Changeset.t()}
  def create_tenant(attrs) do
    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, tenant} = result ->
        provision_tenant_storage(tenant)
        Logger.info("[Platform] Tenant created: #{tenant.name} (#{tenant.slug})")
        result

      {:error, changeset} = error ->
        Logger.warning("[Platform] Tenant creation failed: #{inspect(changeset.errors)}")
        error
    end
  end

  @doc "Updates a tenant's base attributes via the main changeset."
  @spec update_tenant(Tenant.t(), map()) :: {:ok, Tenant.t()} | {:error, Ecto.Changeset.t()}
  def update_tenant(%Tenant{} = tenant, attrs) do
    tenant
    |> Tenant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tenant record from the platform DB.

  > #### Warning {: .warning}
  > This does NOT remove tenant data from disk (`db_path`, `storage_path`).
  > Run a separate cleanup task for filesystem removal.
  """
  @spec delete_tenant(Tenant.t()) :: {:ok, Tenant.t()} | {:error, Ecto.Changeset.t()}
  def delete_tenant(%Tenant{} = tenant), do: Repo.delete(tenant)

  # ═══════════════════════════════════════════════════════════════
  # SUBSCRIPTION STATE MACHINE
  # ═══════════════════════════════════════════════════════════════

  @doc """
  Activates a paid subscription for a tenant.

  Sets status to `"active"`, records the billing cycle, and calculates
  the period end date using calendar-aware arithmetic.

  Uses `DateTime.shift/2` (Elixir 1.19+) which correctly handles:
  - Month boundaries (Jan 31 + 1 month = Feb 28/29, not March 3)
  - Leap years (Feb 29 + 1 year = Feb 28 next year)
  - Varying month lengths (28/29/30/31 days)

  Returns `{:error, reason}` tuple for invalid billing cycle
  instead of raising, so callers get a consistent return type.

  ## Example

      {:ok, tenant} = Platform.activate_tenant(tenant, "monthly")
      {:ok, tenant} = Platform.activate_tenant(tenant, "yearly")
  """
  @spec activate_tenant(Tenant.t(), String.t()) ::
          {:ok, Tenant.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def activate_tenant(%Tenant{} = tenant, billing_cycle)
      when billing_cycle in ~w(monthly yearly) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # DateTime.shift/2 is calendar-aware (Elixir 1.19+).
    # "monthly" on Jan 31 → Feb 28 (not March 3).
    # "yearly" on Feb 29 (leap) → Feb 28 next year (not March 1).
    # DateTime.add/3 with :day would give wrong results for billing.
    period_end =
      case billing_cycle do
        "monthly" -> DateTime.shift(now, month: 1)
        "yearly" -> DateTime.shift(now, year: 1)
      end

    tenant
    |> Tenant.subscription_changeset(%{
      status: "active",
      billing_cycle: billing_cycle,
      current_period_start: now,
      current_period_end: period_end
    })
    |> Repo.update()
    |> tap_log(:info, "Tenant activated (#{billing_cycle}): #{tenant.name}")
  end

  # Guard clause: returns a clear error tuple instead of raising
  # when an invalid billing_cycle is passed.
  def activate_tenant(_tenant, invalid_cycle) do
    {:error,
     "Invalid billing_cycle: #{inspect(invalid_cycle)}. Expected \"monthly\" or \"yearly\"."}
  end

  @doc """
  Starts a free trial for a tenant.

  Checks `trial_used` via pattern matching before loading the plan,
  avoiding a DB call when the trial is already consumed.

  ## Error returns
  - `{:error, :trial_already_used}` — `trial_used` is `true`
  - `{:error, :no_trial_available}` — plan has `trial_period_days: 0`
  """
  @spec start_trial(Tenant.t()) ::
          {:ok, Tenant.t()} | {:error, :trial_already_used | :no_trial_available}

  # FIX: Pattern match on trial_used = true first to short-circuit
  # without loading the plan unnecessarily.
  def start_trial(%Tenant{trial_used: true}), do: {:error, :trial_already_used}

  def start_trial(%Tenant{} = tenant) do
    plan = load_plan(tenant)

    if plan.trial_period_days == 0 do
      {:error, :no_trial_available}
    else
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      # Trial is a fixed number of days (e.g. 14 days, 30 days).
      # DateTime.add/3 with :day is correct here — unlike billing cycles,
      # trial length is not calendar-month based, so DateTime.shift/2
      # is not needed and would give identical results anyway.
      trial_end = DateTime.add(now, plan.trial_period_days, :day)

      tenant
      |> Tenant.trial_changeset(%{
        status: "trialing",
        trial_started_at: now,
        trial_ends_at: trial_end,
        trial_used: true
      })
      |> Repo.update()
      |> tap_log(:info, "Trial started: #{tenant.name}")
    end
  end

  @doc """
  Cancels a tenant's subscription.

  Access continues until `current_period_end` — no immediate cutoff.
  Pass an optional `reason` string for internal audit tracking.
  """
  @spec cancel_tenant(Tenant.t(), String.t() | nil) ::
          {:ok, Tenant.t()} | {:error, Ecto.Changeset.t()}
  def cancel_tenant(%Tenant{} = tenant, reason \\ nil) do
    tenant
    |> Tenant.cancellation_changeset(%{
      status: "cancelled",
      cancelled_at: DateTime.utc_now() |> DateTime.truncate(:second),
      cancellation_reason: reason
    })
    |> Repo.update()
    |> tap_log(:info, "Tenant cancelled: #{tenant.name}")
  end

  @doc """
  Suspends a tenant, immediately cutting off access.

  Sets `active: false` and `status: "suspended"`.
  Use `reinstate_tenant/2` to restore access.
  """
  @spec suspend_tenant(Tenant.t(), String.t() | nil) ::
          {:ok, Tenant.t()} | {:error, Ecto.Changeset.t()}
  def suspend_tenant(%Tenant{} = tenant, reason \\ nil) do
    tenant
    |> Tenant.suspension_changeset(%{
      status: "suspended",
      active: false,
      suspended_at: DateTime.utc_now() |> DateTime.truncate(:second),
      suspension_reason: reason
    })
    |> Repo.update()
    |> tap_log(:warning, "Tenant suspended: #{tenant.name}")
  end

  @doc "Re-activates a suspended or cancelled tenant on a new billing cycle."
  @spec reinstate_tenant(Tenant.t(), String.t()) ::
          {:ok, Tenant.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def reinstate_tenant(%Tenant{} = tenant, billing_cycle) do
    activate_tenant(tenant, billing_cycle)
  end

  @doc """
  Switches a tenant to a different plan without touching subscription status,
  billing cycle, or period dates.
  """
  @spec change_plan(Tenant.t(), Plan.t()) ::
          {:ok, Tenant.t()} | {:error, Ecto.Changeset.t()}
  def change_plan(%Tenant{} = tenant, %Plan{} = new_plan) do
    tenant
    |> Tenant.changeset(%{plan_id: new_plan.id})
    |> Repo.update()
    |> tap_log(:info, "Plan changed for #{tenant.name} → #{new_plan.name}")
  end

  # ═══════════════════════════════════════════════════════════════
  # TRIAL STATUS HELPERS
  # ═══════════════════════════════════════════════════════════════

  @doc "Returns `true` if the tenant's trial period has ended."
  @spec trial_expired?(Tenant.t()) :: boolean()
  def trial_expired?(%Tenant{status: "trialing", trial_ends_at: nil}), do: false

  def trial_expired?(%Tenant{status: "trialing", trial_ends_at: ends_at}) do
    DateTime.compare(DateTime.utc_now(), ends_at) == :gt
  end

  def trial_expired?(_), do: false

  # ═══════════════════════════════════════════════════════════════
  # PRIVATE HELPERS
  # ═══════════════════════════════════════════════════════════════

  # Provisions the tenant's media directory on disk after a successful insert.
  # Non-fatal on failure — the DB record is already committed and the directory
  # can be recreated later without data loss.
  @spec provision_tenant_storage(Tenant.t()) :: :ok
  defp provision_tenant_storage(%Tenant{storage_path: path}) when is_binary(path) do
    case File.mkdir_p(path) do
      :ok ->
        Logger.debug("[Platform] Storage provisioned: #{path}")
        :ok

      {:error, reason} ->
        Logger.error("[Platform] Storage provision failed at #{path}: #{inspect(reason)}")
        :ok
    end
  end

  defp provision_tenant_storage(_), do: :ok

  # Loads the plan association efficiently.
  # If already loaded (e.g. from get_tenant_with_plan!/1), skips the DB call.
  @spec load_plan(Tenant.t()) :: Plan.t()
  defp load_plan(%Tenant{plan: %Plan{} = plan}), do: plan
  defp load_plan(%Tenant{} = tenant), do: Repo.preload(tenant, :plan).plan

  # Passes through a Repo result unchanged while logging on both success and failure.
  # Keeps subscription functions clean — one pipe, one log, no repetition.
  @spec tap_log({:ok | :error, any()}, Logger.level(), String.t()) :: {:ok | :error, any()}
  defp tap_log({:ok, _} = result, level, message) do
    Logger.log(level, "[Platform] #{message}")
    result
  end

  defp tap_log({:error, reason} = result, _level, message) do
    Logger.error("[Platform] FAILED — #{message}: #{inspect(reason)}")
    result
  end
end
