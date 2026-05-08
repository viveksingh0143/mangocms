import Config

# --- Bootstrapping ---
# We use native System.get_env here to ensure this runs before dependencies are downloaded.
database_adapter_name = System.get_env("MANGO_DB", "postgres") |> String.downcase()

repo_adapter =
  case database_adapter_name do
    "postgres" -> Ecto.Adapters.Postgres
    "postgresql" -> Ecto.Adapters.Postgres
    "sqlite" -> Ecto.Adapters.SQLite3
    "sqlite3" -> Ecto.Adapters.SQLite3
    other -> raise "Unsupported MANGO_DB=#{inspect(other)}. Use sqlite3 or postgres."
  end

config :mangocms,
  database_adapter: if(repo_adapter == Ecto.Adapters.Postgres, do: :postgres, else: :sqlite3),
  repo_adapter: repo_adapter,
  namespace: MangoCMS,
  ecto_repos: [MangoCMS.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :mangocms, MangoCMS.Repo, adapter: repo_adapter

config :mangocms, MangoCMS.TenantRepo,
  pool_size: 1,
  journal_mode: :wal,
  cache_size: -64_000,
  foreign_keys: :on,
  busy_timeout: 5_000

# Oban Adapter Selection
oban_adapter_config =
  if repo_adapter == Ecto.Adapters.Postgres do
    [engine: Oban.Engines.Basic, notifier: Oban.Notifiers.Postgres, peer: Oban.Peers.Database]
  else
    [engine: Oban.Engines.Lite]
  end

config :mangocms,
       Oban,
       Keyword.merge(
         [
           repo: MangoCMS.Repo,
           plugins: [
             {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
             {Oban.Plugins.Cron, crontab: [{"0 2 * * *", MangoCMS.Workers.BackupWorker}]}
           ],
           queues: [default: 10, backups: 2, mailers: 5]
         ],
         oban_adapter_config
       )

config :mangocms, MangoCMSWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MangoCMSWeb.ErrorHTML, json: MangoCMSWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MangoCMS.PubSub,
  live_view: [signing_salt: "9+9DzDOq"]

config :mangocms, MangoCMS.Mailer, adapter: Swoosh.Adapters.Local
config :phoenix, :json_library, Jason

# Assets
config :esbuild,
  version: "0.25.4",
  mangocms: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :tailwind,
  version: "4.1.12",
  mangocms: [
    args: ~w(--input=assets/css/app.css --output=priv/static/assets/css/app.css),
    cd: Path.expand("..", __DIR__)
  ]

# --- Environment Specific Compile-Time (Replacing prod.exs) ---
if config_env() == :prod do
  config :logger, level: :info
  config :swoosh, api_client: Swoosh.ApiClient.Req, local: false

  config :mangocms, MangoCMSWeb.Endpoint,
    cache_static_manifest: "priv/static/cache_manifest.json",
    force_ssl: [rewrite_on: [:x_forwarded_proto], exclude: [hosts: ["localhost", "127.0.0.1"]]]
else
  config :logger, :default_formatter, format: "[$level] $message\n", metadata: [:request_id]
end

# Import dev.exs or test.exs strictly for tooling
if config_env() in [:dev, :test] do
  import_config "#{config_env()}.exs"
end
