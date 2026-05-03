defmodule MangoCMS.Platform do
  import Ecto.Query
  alias MangoCMS.Repo
  alias MangoCMS.Platform.{Plan, Tenant}
  require Logger

  # ═══════════════════════════════════════════════════════════════
  # PLANS
  # ═══════════════════════════════════════════════════════════════

  def list_plans, do: Repo.all(Plan)

  def list_active_plans do
    Plan
    |> where([p], p.active == true and p.is_public == true)
    |> order_by([p], asc: p.sort_order)
    |> Repo.all()
  end

  def get_plan(id), do: Repo.get(Plan, id)

  def get_plan!(id), do: Repo.get!(Plan, id)

  def get_plan_by_name(name), do: Repo.get_by(Plan, name: name)

  def create_plan(attrs) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  # ═══════════════════════════════════════════════════════════════
  # TENANTS
  # ═══════════════════════════════════════════════════════════════

  def list_tenants, do: Tenant |> Repo.all()

  def list_tenants_by_status(status), do: Tenant |> where([t], t.status == ^status) |> Repo.all()

  def get_tenant(id), do: Tenant |> Repo.get(id)

  def get_tenant!(id), do: Tenant |> Repo.get!(id)

  def get_tenant_by_domain(domain) do
    Tenant
    |> where([t], t.domain == ^domain and t.active == true)
    |> Repo.one()
  end

  def get_tenant_by_domain_with_plan(domain) do
    Tenant
    |> where([t], t.domain == ^domain and t.active == true)
    |> preload(:plan)
    |> Repo.one()
  end

  def get_tenant_with_plan!(id) do
    Tenant
    |> Repo.get!(id)
    |> Repo.preload(:plan)
  end

  def create_tenant(attrs) do
    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, tenant} ->
        provision_tenant_storage(tenant)
        Logger.info(" mangoCMS [Tenant] Created tenant: #{tenant.name}")
        {:ok, tenant}

      {:error, reason} ->
        Logger.error(" mangoCMS [Tenant] Failed to create tenant: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def update_tenant(%Tenant{} = tenant, attrs) do
    tenant
    |> Tenant.changeset(attrs)
    |> Repo.update()
  end

  # ── Subscription helpers ─────────────────────────────────────

  def activate_tenant(%Tenant{} = tenant, billing_cycle) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    period_end =
      case billing_cycle do
        "monthly" -> DateTime.shift(now, month: 1)
        "yearly" -> DateTime.shift(now, year: 1)
        _ -> raise "mangoCMS [Tenant] Invalid billing_cycle: #{inspect(billing_cycle)}"
      end

    update_tenant(tenant, %{
      status: "active",
      billing_cycle: billing_cycle,
      current_period_start: now,
      current_period_end: period_end,
      trial_ends_at: nil
    })
  end

  def start_trial(%Tenant{} = tenant) do
    plan = tenant.plan || Repo.preload(tenant, :plan).plan

    if plan.trial_period_days == 0 do
      {:error, :no_trial_available}
    else
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      trial_end = DateTime.add(now, plan.trial_period_days, :day)

      update_tenant(tenant, %{
        status: "trialing",
        trial_started_at: now,
        trial_ends_at: trial_end,
        trial_used: true
      })
      |> case do
        {:ok, updated_tenant} ->
          Logger.info(" mangoCMS [Tenant] Trial started for tenant: #{tenant.name}")
          {:ok, updated_tenant}

        {:error, reason} ->
          Logger.error(" mangoCMS [Tenant] Failed to start trial: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  def cancel_tenant(%Tenant{} = tenant, reason \\ nil) do
    update_tenant(tenant, %{
      status: "cancelled",
      cancelled_at: DateTime.utc_now() |> DateTime.truncate(:second),
      cancellation_reason: reason
    })
    |> case do
      {:ok, updated_tenant} ->
        Logger.info(" mangoCMS [Tenant] Cancelled tenant: #{tenant.name}")
        {:ok, updated_tenant}

      {:error, reason} ->
        Logger.error(" mangoCMS [Tenant] Failed to cancel tenant: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # def cancel_tenant(%Tenant{} = tenant, reason \\ nil) do
  #   update_tenant(tenant, %{
  #     status: "cancelled",
  #     cancelled_at: DateTime.utc_now() |> DateTime.truncate(:second),
  #     cancellation_reason: reason
  #   })

  def suspend_tenant(%Tenant{} = tenant, reason \\ nil) do
    update_tenant(tenant, %{
      status: "suspended",
      active: false,
      suspended_at: DateTime.utc_now() |> DateTime.truncate(:second),
      suspension_reason: reason
    })
    |> case do
      {:ok, updated_tenant} ->
        Logger.info(" mangoCMS [Tenant] Suspended tenant: #{tenant.name}")
        {:ok, updated_tenant}

      {:error, reason} ->
        Logger.error(" mangoCMS [Tenant] Failed to suspend tenant: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ── Trial expiry check ───────────────────────────────────────

  def trial_expired?(%Tenant{status: "trialing", trial_ends_at: nil}), do: false

  def trial_expired?(%Tenant{status: "trialing", trial_ends_at: ends_at}) do
    DateTime.compare(DateTime.utc_now(), ends_at) == :gt
  end

  def trial_expired?(_tenant), do: false

  # ── Disk provisioning ────────────────────────────────────────

  defp provision_tenant_storage(%Tenant{storage_path: path}) when is_binary(path) do
    File.mkdir_p(path)
    |> case do
      :ok -> :ok
      err -> Logger.error(" mangoCMS [Tenant] Failed to provision storage: #{inspect(err)}")
    end
  end

  defp provision_tenant_storage(_), do: :ok
end
