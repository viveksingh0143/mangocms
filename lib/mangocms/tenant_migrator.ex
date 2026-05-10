defmodule MangoCMS.TenantMigrator do
  @moduledoc """
  Runs tenant-specific Ecto migrations against a tenant repo.

  Tenant migrations live in `priv/tenant_repo/migrations`, separate from the
  platform migrations in `priv/repo/migrations`.
  """

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.TenantRepo
  alias MangoCMS.TenantRepoManager

  @default_down_step 1

  @spec migrations_path() :: String.t()
  def migrations_path do
    :mangocms
    |> :code.priv_dir()
    |> case do
      path when is_list(path) -> List.to_string(path)
      {:error, :bad_name} -> Path.expand("../../priv", __DIR__)
    end
    |> Path.join("tenant_repo/migrations")
  end

  @spec migrate_tenant!(Tenant.t(), :up | :down, keyword()) :: [integer()]
  def migrate_tenant!(%Tenant{} = tenant, direction \\ :up, opts \\ []) do
    tenant
    |> TenantRepoManager.ensure_repo!(migrate: false)
    |> migrate_repo!(direction, opts)
  end

  @spec migrate_repo!(pid(), :up | :down, keyword()) :: [integer()]
  def migrate_repo!(repo_pid, direction \\ :up, opts \\ []) when direction in [:up, :down] do
    previous_repo = TenantRepo.put_dynamic_repo(repo_pid)
    previous_compiler_options = Code.compiler_options()

    try do
      opts = migrator_opts(direction, opts)
      Code.compiler_options(ignore_module_conflict: true)
      Ecto.Migrator.run(TenantRepo, migrations_path(), direction, opts)
    after
      Code.compiler_options(previous_compiler_options)
      TenantRepo.put_dynamic_repo(previous_repo)
    end
  end

  defp migrator_opts(:up, opts) do
    opts
    |> Keyword.put_new(:all, true)
    |> Keyword.put_new(:log, false)
  end

  defp migrator_opts(:down, opts) do
    opts
    |> Keyword.put_new(:step, @default_down_step)
    |> Keyword.put_new(:log, false)
  end
end
