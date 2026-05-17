defmodule MangoCMSWeb.Router do
  use MangoCMSWeb, :router
  import MangoCMSWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {MangoCMSWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(MangoCMSWeb.Plugs.TenantResolver)
    plug(:fetch_current_user)
  end

  pipeline :require_tenant do
    plug(MangoCMSWeb.Plugs.RequireTenant)
  end

  pipeline :require_platform_auth do
    plug(:require_platform_user)
  end

  pipeline :require_platform_account_auth do
    plug(:require_platform_account_user)
  end

  pipeline :require_tenant_auth do
    plug(:require_tenant_user)
  end

  pipeline :require_tenant_member_auth do
    plug(:require_tenant_member_user)
  end

  pipeline :redirect_platform_authenticated do
    plug(:redirect_if_platform_user)
  end

  pipeline :redirect_platform_account_authenticated do
    plug(:redirect_if_platform_account_user)
  end

  pipeline :redirect_tenant_authenticated do
    plug(:redirect_if_tenant_user)
  end

  pipeline :redirect_tenant_member_authenticated do
    plug(:redirect_if_tenant_member_user)
  end

  pipeline :require_platform_host do
    plug(MangoCMSWeb.Plugs.RequirePlatformHost)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", MangoCMSWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
  end

  scope "/platform/admin", MangoCMSWeb do
    pipe_through([:browser, :require_platform_host, :redirect_platform_authenticated])

    get("/login", AuthController, :new)
    post("/login", AuthController, :create)
    get("/register", AuthController, :register)
    post("/register", AuthController, :create_registration)
    get("/auth/:provider", OAuthController, :request)
    get("/auth/:provider/callback", OAuthController, :callback)
    post("/auth/:provider/callback", OAuthController, :callback)
  end

  scope "/platform", MangoCMSWeb do
    pipe_through([:browser, :require_platform_host, :redirect_platform_account_authenticated])

    get("/login", AuthController, :new)
    post("/login", AuthController, :create)
    get("/register", AuthController, :register)
    post("/register", AuthController, :create_registration)
  end

  scope "/platform/admin", MangoCMSWeb do
    pipe_through([:browser, :require_platform_host, :require_platform_auth])

    get("/dashboard", DashboardController, :platform_admin)
    get("/profile", AuthController, :edit_profile)
    put("/profile", AuthController, :update_profile)
    put("/profile/password", AuthController, :update_password)
    delete("/logout", AuthController, :delete)
  end

  scope "/platform", MangoCMSWeb do
    pipe_through([:browser, :require_platform_host, :require_platform_account_auth])

    get("/dashboard", DashboardController, :platform)
    get("/profile", AuthController, :edit_profile)
    put("/profile", AuthController, :update_profile)
    put("/profile/password", AuthController, :update_password)
    delete("/logout", AuthController, :delete)
  end

  scope "/platform/admin", MangoCMSWeb.Platform.Admin do
    pipe_through([:browser, :require_platform_host, :require_platform_auth])

    live_session :platform_admin,
      on_mount: [{MangoCMSWeb.UserAuth, :require_platform_user}],
      session: {MangoCMSWeb.UserAuth, :live_session, []} do
      live("/plans", PlanLive.Index, :index)
      live("/plans/new", PlanLive.Index, :new)
      live("/plans/:id/edit", PlanLive.Index, :edit)
      live("/plans/:id", PlanLive.Show, :show)
      live("/plans/:id/show/edit", PlanLive.Show, :edit)

      live("/tenants", TenantLive.Index, :index)
      live("/tenants/new", TenantLive.Index, :new)
      live("/tenants/:id/edit", TenantLive.Index, :edit)
      live("/tenants/:id", TenantLive.Show, :show)
      live("/tenants/:id/show/edit", TenantLive.Show, :edit)

      live("/users", UserLive.Index, :index)
      live("/users/new", UserLive.Index, :new)
      live("/users/:id/edit", UserLive.Index, :edit)
    end
  end

  scope "/admin", MangoCMSWeb do
    pipe_through([:browser, :require_tenant, :redirect_tenant_authenticated])

    get("/login", AuthController, :new)
    post("/login", AuthController, :create)
    get("/forgot-password", AuthController, :forgot_password)
    post("/forgot-password", AuthController, :send_reset_password)
    get("/reset-password/:token", AuthController, :reset_password)
    put("/reset-password/:token", AuthController, :update_reset_password)
  end

  scope "/admin", MangoCMSWeb do
    pipe_through([:browser, :require_tenant])

    get("/confirm/:token", AuthController, :confirm)
  end

  scope "/admin", MangoCMSWeb do
    pipe_through([:browser, :require_tenant, :require_tenant_auth])

    get("/dashboard", DashboardController, :tenant_admin)
    get("/profile", AuthController, :edit_profile)
    put("/profile", AuthController, :update_profile)
    put("/profile/password", AuthController, :update_password)
    delete("/logout", AuthController, :delete)
  end

  scope "/admin", MangoCMSWeb.Tenant.Admin do
    pipe_through([:browser, :require_tenant, :require_tenant_auth])

    live_session :tenant_admin,
      on_mount: [
        {MangoCMSWeb.TenantMount, :require_tenant},
        {MangoCMSWeb.UserAuth, :require_tenant_user}
      ],
      session: {MangoCMSWeb.UserAuth, :live_session, []} do
      live("/pages", PageLive.Index, :index)
      live("/pages/new", PageLive.Index, :new)
      live("/pages/:id/edit", PageLive.Index, :edit)
      live("/pages/:id/builder", PageLive.Builder, :builder)
      live("/pages/:id", PageLive.Show, :show)

      live("/sections", SectionLive.Index, :index)
      live("/sections/new", SectionLive.Index, :new)
      live("/sections/:id/edit", SectionLive.Index, :edit)
      live("/sections/:id/builder", SectionLive.Builder, :builder)

      live("/collections", ContentTypeLive.Index, :index)
      live("/collections/new", ContentTypeLive.Index, :new)
      live("/collections/:id/edit", ContentTypeLive.Index, :edit)
      live("/collections/:id", ContentTypeLive.Show, :show)
      live("/collections/:id/fields/new", ContentTypeLive.Show, :new_field)
      live("/collections/:id/fields/:field_id/edit", ContentTypeLive.Show, :edit_field)
      live("/collections/:id/items/new", ContentTypeLive.Show, :new_entry)
      live("/collections/:id/items/:entry_id/edit", ContentTypeLive.Show, :edit_entry)

      live("/users", UserLive.Index, :index)
      live("/users/new", UserLive.Index, :new)
      live("/users/:id/edit", UserLive.Index, :edit)

      live("/settings", SettingsLive.Edit, :edit)
    end
  end

  scope "/", MangoCMSWeb do
    pipe_through([:browser, :require_tenant, :redirect_tenant_member_authenticated])

    get("/login", AuthController, :new)
    post("/login", AuthController, :create)
    get("/register", AuthController, :register)
    post("/register", AuthController, :create_registration)
    get("/forgot-password", AuthController, :forgot_password)
    post("/forgot-password", AuthController, :send_reset_password)
    get("/reset-password/:token", AuthController, :reset_password)
    put("/reset-password/:token", AuthController, :update_reset_password)
  end

  scope "/", MangoCMSWeb do
    pipe_through([:browser, :require_tenant])

    get("/confirm/:token", AuthController, :confirm)
  end

  scope "/", MangoCMSWeb do
    pipe_through([:browser, :require_tenant, :require_tenant_member_auth])

    get("/dashboard", DashboardController, :tenant_member)
    get("/profile", AuthController, :edit_profile)
    put("/profile", AuthController, :update_profile)
    put("/profile/password", AuthController, :update_password)
    delete("/logout", AuthController, :delete)
  end

  scope "/", MangoCMSWeb do
    pipe_through([:browser, :require_tenant])

    live_session :tenant_public_pages,
      on_mount: [
        {MangoCMSWeb.TenantMount, :require_tenant},
        {MangoCMSWeb.UserAuth, :mount_tenant_user}
      ],
      session: {MangoCMSWeb.UserAuth, :live_session, []} do
      live("/:slug", Public.PageLive, :show)
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
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: MangoCMSWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
