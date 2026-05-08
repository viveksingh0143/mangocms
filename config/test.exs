import Config

config :mangocms, MangoCMS.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :mangocms, MangoCMSWeb.Endpoint,
  secret_key_base: "4Bym+GrxQP/cMta5Jq5sk6X97Eyb2VDpzDYtxaeuk5Qbna6mcn4kaTUqEZ9O/9A0",
  server: false

config :mangocms, Oban, testing: :inline
config :mangocms, MangoCMS.Mailer, adapter: Swoosh.Adapters.Test
config :swoosh, :api_client, false
config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view, enable_expensive_runtime_checks: true
config :phoenix, sort_verified_routes_query_params: true
