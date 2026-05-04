defmodule MangoCMS.Repo do
  @adapter Application.compile_env(:mangocms, :repo_adapter, Ecto.Adapters.SQLite3)

  use Ecto.Repo,
    otp_app: :mangocms,
    adapter: @adapter
end
