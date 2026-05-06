import Config
import Dotenvy

# Handle both local dev paths and production Release paths
env_dir_prefix = System.get_env("RELEASE_ROOT") || Path.expand(".")
env_path = Path.join(env_dir_prefix, "envs")

# The Full Source Cascade
source!([
  Path.join(env_path, ".env"),
  Path.join(env_path, ".#{config_env()}.env"),
  Path.join(env_path, ".#{config_env()}.overrides.env"),
  System.get_env()
])

if env!("PHX_SERVER", :boolean, false) do
  config :mangocms, MangoCMSWeb.Endpoint, server: true
end

# Dynamic Ports
default_port = if config_env() == :test, do: 4002, else: 4000
config :mangocms, MangoCMSWeb.Endpoint, http: [port: env!("PORT", :integer!, default_port)]

config :mangocms, :redis,
  host: env!("REDIS_HOST", :string!, "localhost"),
  port: env!("REDIS_PORT", :integer!, 6379)

config :mangocms,
       :tenant_data_root,
       env!("TENANT_DATA_ROOT", :string!, Path.expand("../priv/data/tenants", __DIR__))

# Database Runtime Routing
database_adapter = Application.get_env(:mangocms, :database_adapter)

repo_config =
  if database_adapter == :postgres do
    maybe_ipv6 = if env!("ECTO_IPV6", :boolean, false), do: [:inet6], else: []
    db_url = env!("DATABASE_URL", :string?, nil)

    if db_url do
      [url: db_url, pool_size: env!("POOL_SIZE", :integer!, 10), socket_options: maybe_ipv6]
    else
      [
        username: env!("POSTGRES_USER", :string!, "postgres"),
        password: env!("POSTGRES_PASSWORD", :string!, "postgres"),
        hostname: env!("POSTGRES_HOST", :string!, "localhost"),
        database: env!("POSTGRES_DB", :string!, "mangocms_#{config_env()}"),
        port: env!("POSTGRES_PORT", :integer!, 5432),
        pool_size: env!("POOL_SIZE", :integer!, 10),
        socket_options: maybe_ipv6
      ]
    end
  else
    db_path =
      env!("DATABASE_PATH", :string?, nil) ||
        if config_env() == :test do
          Path.expand(
            "../priv/data/platform/test#{System.get_env("MIX_TEST_PARTITION")}.db",
            __DIR__
          )
        else
          Path.expand("../priv/data/platform/platform.db", __DIR__)
        end

    [
      database: db_path,
      pool_size: env!("POOL_SIZE", :integer!, 5),
      journal_mode: :wal,
      cache_size: -64_000,
      foreign_keys: :on,
      busy_timeout: 5_000
    ]
  end

config :mangocms, MangoCMS.Repo, repo_config

# Production Hard Requirements
if config_env() == :prod do
  host = env!("PHX_HOST", :string!, "example.com")
  dns_query = env!("DNS_CLUSTER_QUERY", :string?, nil)

  if dns_query, do: config(:mangocms, :dns_cluster_query, dns_query)

  config :mangocms, MangoCMSWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}],
    secret_key_base: env!("SECRET_KEY_BASE", :string!)
else
  # Dummy secret for local development
  config :mangocms, MangoCMSWeb.Endpoint,
    secret_key_base:
      env!("SECRET_KEY_BASE", :string!, "dummy_secret_for_dev_c+p8n8gx2NRaoQ2NPkfeUnl8heoTLBzQvR")
end
