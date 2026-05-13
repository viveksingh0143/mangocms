defmodule MangoCMS.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    redis_config = Application.get_env(:mangocms, :redis, [])

    children = [
      # 1. Telemetry
      MangoCMSWeb.Telemetry,

      # 2. Database (SQLite via Ecto)
      MangoCMS.Repo,
      {Registry, keys: :unique, name: MangoCMS.Tenant.RepoRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: MangoCMS.Tenant.RepoSupervisor},

      # 3. Redis connection pool (named :redix)
      {Redix,
       host: redis_config[:host] || "localhost",
       port: redis_config[:port] || 6379,
       database: redis_config[:database] || 0,
       name: :redix},

      # 4. PubSub for LiveView
      {Phoenix.PubSub, name: MangoCMS.PubSub},

      # 5. Background jobs (Oban)
      {Oban, Application.fetch_env!(:mangocms, Oban)},

      # 6. DNS clustering (multi-node, safe to leave for single-node too)
      {DNSCluster, query: Application.get_env(:mangocms, :dns_cluster_query) || :ignore},

      # 7. Web endpoint (last — starts accepting traffic after everything else)
      # Start a worker by calling: MangoCMS.Worker.start_link(arg)
      # {MangoCMS.Worker, arg},
      # Start to serve requests, typically the last entry
      MangoCMSWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MangoCMS.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MangoCMSWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
