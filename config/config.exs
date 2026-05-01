# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mangocms, MangoCMS.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: Path.expand("../priv/data/platform/platform.db", __DIR__),
  pool_size: 5,
  # WAL = better concurrent reads
  journal_mode: :wal,
  # 64 MB page cache
  cache_size: -64000,
  foreign_keys: :on,
  busy_timeout: 5_000

config :mangocms,
  namespace: MangoCMS,
  ecto_repos: [MangoCMS.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  tenant_data_root: Path.expand("../priv/data/tenants", __DIR__)

# Redis connection defaults
config :mangocms, :redis,
  hostname: "localhost",
  port: 6379,
  database: 0

# Oban — background jobs with cron schedule
config :mangocms, Oban,
  repo: MangoCMS.Repo,
  plugins: [
    # Prune completed jobs older than 7 days
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},

    # Schedule daily backup at 2:00 AM
    {Oban.Plugins.Cron,
     crontab: [
       {"0 2 * * *", MangoCMS.Workers.BackupWorker}
     ]}
  ],
  queues: [default: 10, backups: 2, mailers: 5]

# Configure the endpoint
config :mangocms, MangoCMSWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MangoCMSWeb.ErrorHTML, json: MangoCMSWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MangoCMS.PubSub,
  live_view: [signing_salt: "9+9DzDOq"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :mangocms, MangoCMS.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  mangocms: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  mangocms: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
