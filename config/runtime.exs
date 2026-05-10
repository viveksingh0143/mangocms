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

tenant_data_root_default =
  if config_env() == :test do
    Path.expand("../tmp/tenants", __DIR__)
  else
    Path.expand("../priv/data/tenants", __DIR__)
  end

config :mangocms, :tenant_data_root, env!("TENANT_DATA_ROOT", :string!, tenant_data_root_default)
config :mangocms, :tenant_base_host, env!("TENANT_BASE_HOST", :string!, "mangocms.local")

config :mangocms,
       :tenant_postgres_database_prefix,
       env!("TENANT_POSTGRES_DATABASE_PREFIX", :string!, "mangocms_tenant_")

config :mangocms, :sso,
  google: [
    client_id: env!("GOOGLE_CLIENT_ID", :string?, nil),
    client_secret: env!("GOOGLE_CLIENT_SECRET", :string?, nil),
    authorization_url: "https://accounts.google.com/o/oauth2/v2/auth",
    token_url: "https://oauth2.googleapis.com/token",
    userinfo_url: "https://openidconnect.googleapis.com/v1/userinfo",
    scopes: ~w(openid email profile)
  ],
  outlook: [
    client_id: env!("MICROSOFT_CLIENT_ID", :string?, nil),
    client_secret: env!("MICROSOFT_CLIENT_SECRET", :string?, nil),
    authorization_url: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
    token_url: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
    userinfo_url: "https://graph.microsoft.com/oidc/userinfo",
    scopes: ~w(openid email profile)
  ],
  apple: [
    client_id: env!("APPLE_CLIENT_ID", :string?, nil),
    client_secret: env!("APPLE_CLIENT_SECRET", :string?, nil),
    authorization_url: "https://appleid.apple.com/auth/authorize",
    token_url: "https://appleid.apple.com/auth/token",
    userinfo_url: nil,
    response_mode: "form_post",
    scopes: ~w(name email)
  ]

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

tenant_database_adapter = Application.get_env(:mangocms, :tenant_database_adapter, :sqlite3)

tenant_repo_config =
  if tenant_database_adapter == :postgres do
    maybe_ipv6 = if env!("TENANT_POSTGRES_IPV6", :boolean, false), do: [:inet6], else: []

    [
      username:
        env!("TENANT_POSTGRES_USER", :string!, env!("POSTGRES_USER", :string!, "postgres")),
      password:
        env!(
          "TENANT_POSTGRES_PASSWORD",
          :string!,
          env!("POSTGRES_PASSWORD", :string!, "postgres")
        ),
      hostname:
        env!("TENANT_POSTGRES_HOST", :string!, env!("POSTGRES_HOST", :string!, "localhost")),
      port: env!("TENANT_POSTGRES_PORT", :integer!, env!("POSTGRES_PORT", :integer!, 5432)),
      pool_size: env!("TENANT_POOL_SIZE", :integer!, 1),
      socket_options: maybe_ipv6
    ]
  else
    [
      pool_size: env!("TENANT_POOL_SIZE", :integer!, 1),
      journal_mode: :wal,
      cache_size: -64_000,
      foreign_keys: :on,
      busy_timeout: 5_000
    ]
  end

config :mangocms, MangoCMS.TenantRepo, tenant_repo_config

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
      env!(
        "SECRET_KEY_BASE",
        :string!,
        "dummy_secret_for_local_dev_and_test_only_64_bytes_minimum_value_keep_private"
      )
end
