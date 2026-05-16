defmodule MangoCMS.Workers.PrunePageVersions do
  @moduledoc """
  Prunes noisy automatic page versions for a tenant page.

  Manual and publish checkpoint versions are never deleted.
  """

  use Oban.Worker, queue: :default, unique: [period: 3600]

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.Pages

  @auto_retention_limit 50

  @impl true
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id, "page_id" => page_id}}) do
    tenant = Platform.get_tenant_with_plan!(tenant_id)
    Pages.prune_auto_page_versions(tenant, page_id, @auto_retention_limit)
    :ok
  end
end
