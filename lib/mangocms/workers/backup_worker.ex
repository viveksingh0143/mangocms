defmodule MangoCMS.Workers.BackupWorker do
  use Oban.Worker,
    queue: :backups,
    max_attempts: 3,
    # deduplicate — only one backup job per day
    unique: [period: 86_400]

  require Logger

  alias MangoCMS.Platform

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id}}) do
    tenant = Platform.get_tenant!(tenant_id)

    backup_dir = Path.join([tenant.storage_path, "backups"])
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic)
    backup_path = Path.join(backup_dir, "tenant-#{timestamp}.db")

    File.mkdir_p!(backup_dir)

    case File.copy(tenant.db_path, backup_path) do
      {:ok, _bytes} ->
        Logger.info("[BackupWorker] Backed up tenant #{tenant.slug} → #{backup_path}")
        :ok

      {:error, reason} ->
        Logger.error("[BackupWorker] Failed to backup #{tenant.slug}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Called with no tenant_id → backs up ALL active tenants
  def perform(%Oban.Job{args: %{}}) do
    Platform.list_tenants()
    |> Enum.filter(& &1.active)
    |> Enum.each(fn tenant ->
      %{"tenant_id" => tenant.id}
      |> MangoCMS.Workers.BackupWorker.new()
      |> Oban.insert()
    end)

    :ok
  end
end
