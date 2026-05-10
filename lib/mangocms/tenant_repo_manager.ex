defmodule MangoCMS.TenantRepoManager do
  @moduledoc """
  Starts and prepares the configured repo that belongs to a single tenant.
  """

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.TenantMigrator
  alias MangoCMS.TenantRepo

  @registry MangoCMS.TenantRepoRegistry
  @supervisor MangoCMS.TenantRepoSupervisor

  @doc "Runs a function with `MangoCMS.TenantRepo` pointed at the tenant database."
  @spec with_repo(Tenant.t(), (module() -> result), keyword()) :: result when result: var
  def with_repo(%Tenant{} = tenant, fun, opts \\ []) when is_function(fun, 1) do
    repo_pid = ensure_repo!(tenant, opts)
    previous_repo = TenantRepo.put_dynamic_repo(repo_pid)

    try do
      fun.(TenantRepo)
    after
      TenantRepo.put_dynamic_repo(previous_repo)
    end
  end

  @doc "Ensures the tenant repo process exists. Tenant migrations run only when requested."
  @spec ensure_repo!(Tenant.t(), keyword()) :: pid()
  def ensure_repo!(%Tenant{id: tenant_id} = tenant, opts \\ []) when is_binary(tenant_id) do
    repo_opts = repo_opts(tenant)
    maybe_create_storage!(repo_opts)

    repo_name = repo_name(tenant)

    child_spec =
      Supervisor.child_spec(
        {TenantRepo, Keyword.put(repo_opts, :name, repo_name)},
        id: {:tenant_repo, tenant_id}
      )

    repo_pid =
      case DynamicSupervisor.start_child(@supervisor, child_spec) do
        {:ok, pid} ->
          pid

        {:error, {:already_started, pid}} ->
          pid

        {:error, {:already_present, _child}} ->
          repo_pid!(tenant_id)

        {:error, reason} ->
          raise "could not start tenant repo for #{tenant.slug}: #{inspect(reason)}"
      end

    if Keyword.get(opts, :migrate, false) do
      TenantMigrator.migrate_repo!(repo_pid, :up, all: true)
    end

    repo_pid
  end

  defp repo_opts(%Tenant{} = tenant) do
    :mangocms
    |> Application.get_env(TenantRepo, [])
    |> Keyword.merge(database_opts(tenant))
    |> Keyword.put_new(:pool_size, 1)
  end

  defp repo_name(%Tenant{id: tenant_id}), do: {:via, Registry, {@registry, tenant_id}}

  defp repo_pid!(tenant_id) do
    case Registry.lookup(@registry, tenant_id) do
      [{pid, _}] -> pid
      [] -> raise "tenant repo #{tenant_id} was already present but not registered"
    end
  end

  defp database_opts(%Tenant{} = tenant) do
    case tenant_database_adapter() do
      :postgres -> [database: postgres_database_name(tenant)]
      :sqlite3 -> [database: sqlite_database_path!(tenant)]
    end
  end

  defp maybe_create_storage!(repo_opts) do
    case tenant_database_adapter() do
      :postgres ->
        case Ecto.Adapters.Postgres.storage_up(repo_opts) do
          :ok ->
            :ok

          {:error, :already_up} ->
            :ok

          {:error, reason} ->
            raise "could not create tenant postgres database: #{inspect(reason)}"
        end

      :sqlite3 ->
        repo_opts
        |> Keyword.fetch!(:database)
        |> Path.dirname()
        |> File.mkdir_p!()
    end
  end

  defp sqlite_database_path!(%Tenant{db_path: db_path}) when is_binary(db_path), do: db_path

  defp sqlite_database_path!(%Tenant{} = tenant) do
    raise "tenant #{inspect(tenant.id)} does not have a SQLite db_path"
  end

  defp postgres_database_name(%Tenant{db_path: db_path, slug: slug}) do
    if postgres_database_name?(db_path), do: db_path, else: default_postgres_database_name(slug)
  end

  defp postgres_database_name?(value) when is_binary(value) do
    Path.dirname(value) == "." and Path.extname(value) == ""
  end

  defp postgres_database_name?(_), do: false

  defp default_postgres_database_name(slug) do
    prefix = Application.get_env(:mangocms, :tenant_postgres_database_prefix, "mangocms_tenant_")
    prefix <> slug
  end

  defp tenant_database_adapter do
    Application.get_env(:mangocms, :tenant_database_adapter, :sqlite3)
  end
end
