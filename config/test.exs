import Config

config :mangocms, MangoCMS.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :mangocms, MangoCMSWeb.Endpoint, server: false

config :mangocms, Oban, testing: :inline
config :mangocms, MangoCMS.Mailer, adapter: Swoosh.Adapters.Test
config :swoosh, :api_client, false
config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view, enable_expensive_runtime_checks: true
config :phoenix, sort_verified_routes_query_params: true
