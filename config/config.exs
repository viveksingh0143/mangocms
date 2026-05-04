# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

database_adapter =
  System.get_env("MANGO_DB", "sqlite3")
  |> String.downcase()

repo_adapter =
  case database_adapter do
    "postgres" -> Ecto.Adapters.Postgres
    "postgresql" -> Ecto.Adapters.Postgres
    "sqlite" -> Ecto.Adapters.SQLite3
    "sqlite3" -> Ecto.Adapters.SQLite3
    other -> raise "Unsupported MANGO_DB=#{inspect(other)}. Use sqlite3 or postgres."
  end

config :mangocms,
  database_adapter: if(repo_adapter == Ecto.Adapters.Postgres, do: :postgres, else: :sqlite3),
  repo_adapter: repo_adapter

sqlite_database =
  case config_env() do
    :test ->
      Path.expand(
        "../priv/data/platform/test#{System.get_env("MIX_TEST_PARTITION")}.db",
        __DIR__
      )

    _ ->
      Path.expand("../priv/data/platform/platform.db", __DIR__)
  end

postgres_database =
  case config_env() do
    :test -> "mangocms_test#{System.get_env("MIX_TEST_PARTITION")}"
    :prod -> "mangocms_prod"
    _ -> "mangocms_dev"
  end

repo_config =
  case repo_adapter do
    Ecto.Adapters.Postgres ->
      if database_url = System.get_env("DATABASE_URL") do
        [
          url: database_url,
          pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
        ]
      else
        [
          username: System.get_env("POSTGRES_USER") || "postgres",
          password: System.get_env("POSTGRES_PASSWORD") || "postgres",
          hostname: System.get_env("POSTGRES_HOST") || "localhost",
          port: String.to_integer(System.get_env("POSTGRES_PORT") || "5432"),
          database: System.get_env("POSTGRES_DB") || postgres_database,
          pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
        ]
      end

    Ecto.Adapters.SQLite3 ->
      [
        database: sqlite_database,
        pool_size: 5,
        # WAL = better concurrent reads
        journal_mode: :wal,
        # 64 MB page cache
        cache_size: -64_000,
        foreign_keys: :on,
        busy_timeout: 5_000
      ]
  end

config :mangocms, MangoCMS.Repo, repo_config

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
oban_adapter_config =
  case repo_adapter do
    Ecto.Adapters.Postgres ->
      [
        engine: Oban.Engines.Basic,
        notifier: Oban.Notifiers.Postgres,
        peer: Oban.Peers.Database
      ]

    Ecto.Adapters.SQLite3 ->
      [
        engine: Oban.Engines.Lite
      ]
  end

oban_config = [
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
]

config :mangocms, Oban, Keyword.merge(oban_config, oban_adapter_config)

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
