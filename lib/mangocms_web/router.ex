defmodule MangoCMSWeb.Router do
  use MangoCMSWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MangoCMSWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MangoCMSWeb.Plugs.TenantResolver
  end

  pipeline :require_tenant do
    plug MangoCMSWeb.Plugs.RequireTenant
  end

  pipeline :require_platform_host do
    plug MangoCMSWeb.Plugs.RequirePlatformHost
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MangoCMSWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/platform/admin", MangoCMSWeb.Platform.Admin do
    pipe_through [:browser, :require_platform_host]

    live "/plans", PlanLive.Index, :index
    live "/plans/new", PlanLive.Index, :new
    live "/plans/:id/edit", PlanLive.Index, :edit
    live "/plans/:id", PlanLive.Show, :show
    live "/plans/:id/show/edit", PlanLive.Show, :edit

    live "/tenants", TenantLive.Index, :index
    live "/tenants/new", TenantLive.Index, :new
    live "/tenants/:id/edit", TenantLive.Index, :edit
    live "/tenants/:id", TenantLive.Show, :show
    live "/tenants/:id/show/edit", TenantLive.Show, :edit
  end

  scope "/admin", MangoCMSWeb.Tenant.Admin do
    pipe_through [:browser, :require_tenant]

    live_session :tenant_admin,
      on_mount: [{MangoCMSWeb.TenantMount, :require_tenant}],
      session: {MangoCMSWeb.Plugs.TenantResolver, :live_session, []} do
      live "/products", ProductLive.Index, :index
      live "/products/new", ProductLive.Index, :new
      live "/products/:id/edit", ProductLive.Index, :edit
      live "/products/:id", ProductLive.Show, :show
      live "/products/:id/show/edit", ProductLive.Show, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MangoCMSWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mangocms, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MangoCMSWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
