defmodule Mix.Tasks.Tenant.Migrate do
  @moduledoc """
  Runs tenant migrations up for one tenant or all tenants.

      mix tenant.migrate
      mix tenant.migrate --all
      mix tenant.migrate --tenant acme
      mix tenant.migrate --tenant 8ec5f9a7-...

  Tenant migrations are loaded from `priv/tenant_repo/migrations`.
  """

  use Mix.Task

  alias MangoCMS.Platform
  alias MangoCMS.TenantMigrator

  @shortdoc "Runs tenant migrations up"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    {opts, _args} =
      OptionParser.parse!(args,
        strict: [tenant: :string, all: :boolean, step: :integer, to: :integer],
        aliases: [t: :tenant]
      )

    migrator_opts = migrator_opts(opts, :up)

    opts
    |> tenants()
    |> Enum.each(fn tenant ->
      versions = TenantMigrator.migrate_tenant!(tenant, :up, migrator_opts)
      Mix.shell().info("Migrated tenant #{tenant.slug}: #{format_versions(versions)}")
    end)
  end

  defp tenants(opts) do
    try do
      case Keyword.get(opts, :tenant) do
        nil -> Platform.list_tenants()
        key -> [find_tenant!(key)]
      end
    rescue
      error in [Ecto.QueryError, Exqlite.Error, Postgrex.Error] ->
        Mix.raise(
          "Could not load platform tenants. Run platform migrations first. #{Exception.message(error)}"
        )
    end
  end

  defp find_tenant!(key) do
    Platform.list_tenants()
    |> Enum.find(&tenant_matches?(&1, key))
    |> case do
      nil -> Mix.raise("Tenant #{inspect(key)} was not found by id, slug, subdomain, or domain")
      tenant -> tenant
    end
  end

  defp tenant_matches?(tenant, key) do
    key in [tenant.id, tenant.slug, tenant.subdomain, tenant.domain]
  end

  defp migrator_opts(opts, _direction) do
    cond do
      Keyword.has_key?(opts, :to) -> [to: Keyword.fetch!(opts, :to)]
      Keyword.has_key?(opts, :step) -> [step: Keyword.fetch!(opts, :step)]
      true -> [all: true]
    end
  end

  defp format_versions([]), do: "already up"
  defp format_versions(versions), do: Enum.map_join(versions, ", ", &to_string/1)
end
