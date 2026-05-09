defmodule MangoCMS.TenantRepoManager do
  @moduledoc """
  Starts and prepares the SQLite repo that belongs to a single tenant.
  """

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.TenantRepo

  @registry MangoCMS.TenantRepoRegistry
  @supervisor MangoCMS.TenantRepoSupervisor

  @doc "Runs a function with `MangoCMS.TenantRepo` pointed at the tenant database."
  @spec with_repo(Tenant.t(), (module() -> result)) :: result when result: var
  def with_repo(%Tenant{} = tenant, fun) when is_function(fun, 1) do
    repo_pid = ensure_repo!(tenant)
    previous_repo = TenantRepo.put_dynamic_repo(repo_pid)

    try do
      fun.(TenantRepo)
    after
      TenantRepo.put_dynamic_repo(previous_repo)
    end
  end

  @doc "Ensures the tenant repo process and expected tenant tables exist."
  @spec ensure_repo!(Tenant.t()) :: pid()
  def ensure_repo!(%Tenant{id: tenant_id, db_path: db_path} = tenant)
      when is_binary(tenant_id) and is_binary(db_path) do
    File.mkdir_p!(Path.dirname(db_path))

    repo_name = repo_name(tenant)

    child_spec =
      Supervisor.child_spec(
        {TenantRepo, repo_opts(db_path, repo_name)},
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

    ensure_schema!(repo_pid)
    repo_pid
  end

  defp repo_opts(db_path, repo_name) do
    :mangocms
    |> Application.get_env(TenantRepo, [])
    |> Keyword.merge(database: db_path, name: repo_name)
    |> Keyword.put_new(:pool_size, 1)
  end

  defp repo_name(%Tenant{id: tenant_id}), do: {:via, Registry, {@registry, tenant_id}}

  defp repo_pid!(tenant_id) do
    case Registry.lookup(@registry, tenant_id) do
      [{pid, _}] -> pid
      [] -> raise "tenant repo #{tenant_id} was already present but not registered"
    end
  end

  defp ensure_schema!(repo_pid) do
    previous_repo = TenantRepo.put_dynamic_repo(repo_pid)

    try do
      TenantRepo.query!("""
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        slug TEXT NOT NULL,
        sku TEXT,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        price INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'INR',
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        inserted_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
      """)

      TenantRepo.query!("CREATE UNIQUE INDEX IF NOT EXISTS products_slug_index ON products(slug)")

      TenantRepo.query!("""
      CREATE UNIQUE INDEX IF NOT EXISTS products_sku_index
      ON products(sku)
      WHERE sku IS NOT NULL AND sku != ''
      """)

      TenantRepo.query!("CREATE INDEX IF NOT EXISTS products_status_index ON products(status)")
      TenantRepo.query!("CREATE INDEX IF NOT EXISTS products_active_index ON products(active)")

      TenantRepo.query!("""
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        identity_key TEXT NOT NULL,
        email TEXT NOT NULL,
        hashed_password TEXT,
        full_name TEXT,
        phone TEXT,
        avatar_url TEXT,
        locale TEXT NOT NULL DEFAULT 'en',
        timezone TEXT NOT NULL DEFAULT 'UTC',
        role TEXT NOT NULL DEFAULT 'member',
        confirmed_at TEXT,
        disabled_at TEXT,
        inserted_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
      """)

      TenantRepo.query!(
        "CREATE UNIQUE INDEX IF NOT EXISTS users_identity_key_index ON users(identity_key)"
      )

      TenantRepo.query!("CREATE INDEX IF NOT EXISTS users_email_index ON users(email)")
      TenantRepo.query!("CREATE INDEX IF NOT EXISTS users_role_index ON users(role)")

      TenantRepo.query!("""
      CREATE TABLE IF NOT EXISTS user_tokens (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        token BLOB NOT NULL,
        context TEXT NOT NULL,
        inserted_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
      """)

      TenantRepo.query!(
        "CREATE UNIQUE INDEX IF NOT EXISTS user_tokens_token_context_index ON user_tokens(token, context)"
      )

      TenantRepo.query!(
        "CREATE INDEX IF NOT EXISTS user_tokens_user_id_index ON user_tokens(user_id)"
      )
    after
      TenantRepo.put_dynamic_repo(previous_repo)
    end
  end
end
