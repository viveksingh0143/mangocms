defmodule MangoCMS.TenantRepo do
  use Ecto.Repo,
    otp_app: :mangocms,
    adapter: Ecto.Adapters.SQLite3
end
