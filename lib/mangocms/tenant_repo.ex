defmodule MangoCMS.TenantRepo do
  @adapter Application.compile_env(:mangocms, :tenant_repo_adapter, Ecto.Adapters.SQLite3)

  use Ecto.Repo,
    otp_app: :mangocms,
    adapter: @adapter
end
