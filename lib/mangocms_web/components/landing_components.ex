defmodule MangoCMSWeb.LandingComponents do
  @moduledoc "Reusable daisyUI landing page components."

  use MangoCMSWeb, :html

  alias MangoCMS.Authorization
  alias MangoCMS.Tenant.Settings, as: TenantSettings

  attr :id, :string, default: nil
  attr :current_user, :any, default: nil
  attr :current_tenant, :any, default: nil
  attr :current_tenant_settings, :any, default: nil
  attr :platform_registration_enabled, :boolean, default: false

  def landing_navbar(assigns) do
    assigns =
      assigns
      |> assign(
        :brand_label,
        brand_label(assigns.current_tenant, assigns.current_tenant_settings)
      )
      |> assign(:brand_logo_url, TenantSettings.logo_url(assigns.current_tenant_settings))
      |> assign(
        :brand_dark_logo_url,
        TenantSettings.dark_logo_url(assigns.current_tenant_settings)
      )
      |> assign(:login_href, login_href(assigns.current_tenant))
      |> assign(:register_href, register_href(assigns.current_tenant))
      |> assign(:account_label, account_label(assigns.current_user))
      |> assign(:account_initials, account_initials(assigns.current_user))
      |> assign(:account_avatar_url, account_avatar_url(assigns.current_user))
      |> assign(:dashboard_href, dashboard_href(assigns.current_tenant, assigns.current_user))
      |> assign(:profile_href, profile_href(assigns.current_tenant, assigns.current_user))
      |> assign(:logout_href, logout_href(assigns.current_tenant, assigns.current_user))

    ~H"""
    <div
      id={@id}
      class="navbar sticky top-0 z-40 border-b border-base-300 bg-base-100/90 px-4 backdrop-blur lg:px-8"
    >
      <div class="navbar-start">
        <.link href={~p"/"} class="flex items-center gap-3">
          <img
            src={@brand_logo_url || ~p"/images/logo.png"}
            alt={@brand_label}
            class="rounded-box object-contain dark:hidden"
          />
          <img
            src={@brand_dark_logo_url || @brand_logo_url || ~p"/images/white-logo.png"}
            alt={@brand_label}
            class="hidden rounded-box object-contain dark:block"
          />
        </.link>
      </div>

      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal gap-1 px-1">
          <li><a href="#services">Services</a></li>
          <li><a href="#ai-chat">AI Chat</a></li>
          <li><a href="#plans">Plans</a></li>
          <li><a href="#reviews">Reviews</a></li>
        </ul>
      </div>

      <div class="navbar-end gap-2">
        <Layouts.theme_toggle />
        <details :if={@current_user} id="landing-account-menu" class="dropdown dropdown-end">
          <summary
            id="landing-account-menu-button"
            class="btn btn-primary btn-sm list-none gap-2"
          >
            <img
              :if={@account_avatar_url}
              id="landing-account-avatar"
              src={@account_avatar_url}
              alt={@account_label}
              class="size-5 rounded-full object-cover"
            />
            <span
              :if={!@account_avatar_url}
              id="landing-account-initials"
              class="grid size-5 place-items-center rounded-full bg-primary-content/20 text-[0.65rem] font-bold"
            >
              {@account_initials}
            </span>
            <span class="hidden sm:inline">{@account_label}</span>
            <.icon name="hero-chevron-down-micro" class="size-4" />
          </summary>
          <ul class="menu dropdown-content z-50 mt-2 w-48 rounded-box border border-base-300 bg-base-100 p-2 text-base-content shadow-lg">
            <li>
              <.link id="landing-dashboard-link" href={@dashboard_href}>Dashboard</.link>
            </li>
            <li>
              <.link id="landing-profile-link" href={@profile_href}>Profile</.link>
            </li>
            <li>
              <.link id="landing-logout-link" href={@logout_href} method="delete">Logout</.link>
            </li>
          </ul>
        </details>
        <.link
          :if={!@current_user}
          href={@login_href}
          class="btn btn-ghost btn-sm"
        >
          Login
        </.link>
        <.link
          :if={!@current_user && @register_href}
          href={@register_href}
          class="btn btn-primary btn-sm"
        >
          Register
        </.link>
      </div>
    </div>
    """
  end

  attr :class, :any, default: nil
  slot :inner_block, required: true

  def landing_main(assigns) do
    ~H"""
    <main class={["bg-base-100 text-base-content", @class]}>
      {render_slot(@inner_block)}
    </main>
    """
  end

  attr :href, :string, default: "#"
  attr :text, :string, required: true
  attr :cta, :string, default: nil

  def announcement_badge(assigns) do
    ~H"""
    <.link
      href={@href}
      class="badge badge-outline badge-lg gap-2 border-primary/40 bg-primary/5 text-primary"
    >
      <span class="size-2 rounded-full bg-primary"></span>
      {@text}
      <span :if={@cta} class="hidden font-semibold sm:inline">{@cta}</span>
    </.link>
    """
  end

  attr :id, :string, default: nil
  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  slot :actions
  slot :demo
  slot :footer

  def hero_section(assigns) do
    ~H"""
    <section id={@id} class="hero overflow-hidden bg-base-100">
      <div class="hero-content w-full max-w-desktop flex-col gap-12 px-4 py-16 sm:px-6 lg:px-8 lg:py-24">
        <div class="mx-auto max-w-4xl text-center">
          <.announcement_badge
            :if={@eyebrow}
            text={@eyebrow}
            cta="Read the architecture"
            href="#architecture"
          />
          <h1 class="mt-8 text-5xl font-black tracking-tight text-balance sm:text-6xl lg:text-7xl">
            {@title}
          </h1>
          <p class="mx-auto mt-6 max-w-2xl text-lg leading-8 text-base-content/70">
            {@subtitle}
          </p>
          <div :if={@actions != []} class="mt-8 flex flex-wrap items-center justify-center gap-3">
            {render_slot(@actions)}
          </div>
        </div>

        <div :if={@demo != []} class="w-full">
          {render_slot(@demo)}
        </div>

        <div :if={@footer != []} class="w-full">
          {render_slot(@footer)}
        </div>
      </div>
    </section>
    """
  end

  attr :id, :string, default: nil
  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  slot :actions
  slot :inner_block, required: true

  def landing_section(assigns) do
    ~H"""
    <section id={@id} class={["px-4 py-16 sm:px-6 lg:px-8 lg:py-24", @class]}>
      <div class="mx-auto max-w-desktop">
        <div class="max-w-3xl">
          <p :if={@eyebrow} class="text-sm font-bold uppercase tracking-wide text-primary">
            {@eyebrow}
          </p>
          <h2 class="mt-3 text-3xl font-black tracking-tight text-balance sm:text-4xl">
            {@title}
          </h2>
          <p :if={@subtitle} class="mt-4 text-lg leading-8 text-base-content/70">
            {@subtitle}
          </p>
        </div>
        <div :if={@actions != []} class="mt-8">
          {render_slot(@actions)}
        </div>
        <div class="mt-10">
          {render_slot(@inner_block)}
        </div>
      </div>
    </section>
    """
  end

  attr :items, :list, required: true

  def logo_grid(assigns) do
    ~H"""
    <div class="mx-auto grid max-w-5xl grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
      <div
        :for={item <- @items}
        class="card card-sm border border-base-300 bg-base-100 text-center shadow-sm"
      >
        <div class="card-body items-center">
          <span class="badge badge-neutral badge-outline">{item.label}</span>
          <p class="text-xs text-base-content/60">{item.text}</p>
        </div>
      </div>
    </div>
    """
  end

  attr :metrics, :list, required: true

  def metrics_stats(assigns) do
    ~H"""
    <div class="stats stats-vertical w-full border border-base-300 bg-base-100 shadow-sm lg:stats-horizontal">
      <div :for={metric <- @metrics} class="stat">
        <div class="stat-title">{metric.label}</div>
        <div class="stat-value text-primary">{metric.value}</div>
        <div class="stat-desc">{metric.description}</div>
      </div>
    </div>
    """
  end

  attr :features, :list, required: true

  def feature_stack(assigns) do
    ~H"""
    <div class="grid gap-6 lg:grid-cols-3">
      <article
        :for={feature <- @features}
        class="card border border-base-300 bg-base-100 shadow-sm transition hover:-translate-y-1 hover:shadow-md"
      >
        <div class="card-body">
          <div class="flex items-start justify-between gap-4">
            <div class={["badge gap-2", feature.badge_class]}>
              <.icon name={feature.icon} class="size-4" />
              {feature.badge}
            </div>
          </div>
          <h3 class="card-title mt-4">{feature.title}</h3>
          <p class="text-base-content/70">{feature.text}</p>
          <div class="card-actions mt-4">
            <a href={feature.href} class="link link-primary font-semibold">
              Learn more
            </a>
          </div>
        </div>
      </article>
    </div>
    """
  end

  attr :services, :list, required: true

  def service_cards(assigns) do
    ~H"""
    <div class="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
      <article
        :for={service <- @services}
        class="card border border-base-300 bg-base-100 shadow-sm transition hover:-translate-y-1 hover:shadow-md"
      >
        <div class="card-body">
          <div class={["badge gap-2", service.badge_class]}>
            <.icon name={service.icon} class="size-4" />
            {service.badge}
          </div>
          <h3 class="card-title mt-4">{service.title}</h3>
          <p class="text-base-content/70">{service.text}</p>
          <ul class="mt-4 space-y-2 text-sm text-base-content/70">
            <li :for={point <- service.points} class="flex gap-2">
              <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-success" />
              <span>{point}</span>
            </li>
          </ul>
        </div>
      </article>
    </div>
    """
  end

  attr :questions, :list, required: true

  def ai_chat_showcase(assigns) do
    ~H"""
    <div class="grid gap-8 lg:grid-cols-[0.9fr_1.1fr]">
      <div class="card border border-base-300 bg-base-100 shadow-sm">
        <div class="card-body">
          <div class="badge badge-primary gap-2">
            <.icon name="hero-sparkles" class="size-4" /> AI Chat
          </div>
          <h3 class="mt-4 text-3xl font-black tracking-tight">
            A website assistant trained around your pages.
          </h3>
          <p class="mt-2 text-base-content/70">
            Add an AI chat widget that answers visitor questions about your services, pricing,
            experience, product features, policies, and contact details using the content already
            published on your website.
          </p>
          <div class="mt-6 grid gap-3 sm:grid-cols-2">
            <div class="stat rounded-box border border-base-300 bg-base-200">
              <div class="stat-title">Reply style</div>
              <div class="stat-value text-xl">On-brand</div>
            </div>
            <div class="stat rounded-box border border-base-300 bg-base-200">
              <div class="stat-title">Coverage</div>
              <div class="stat-value text-xl">Site-aware</div>
            </div>
          </div>
        </div>
      </div>

      <div class="mockup-window border border-base-300 bg-base-300 shadow-xl">
        <div class="space-y-4 bg-base-100 p-6">
          <div class="chat chat-start">
            <div class="chat-bubble chat-bubble-neutral">
              Can you build a product feature website and explain our pricing?
            </div>
          </div>
          <div class="chat chat-end">
            <div class="chat-bubble chat-bubble-primary">
              Yes. We can structure feature pages, plan sections, FAQs, and calls to action, then
              answer questions from visitors using your approved website content.
            </div>
          </div>
          <div
            :for={question <- @questions}
            class="rounded-box border border-base-300 bg-base-200 p-3 text-sm"
          >
            <span class="font-semibold">{question.label}</span>
            <span class="text-base-content/60">
              <span aria-hidden="true">-</span>
              <span>{question.text}</span>
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :companies, :list, required: true

  def company_references(assigns) do
    ~H"""
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <div
        :for={company <- @companies}
        class="card card-sm border border-base-300 bg-base-100 shadow-sm"
      >
        <div class="card-body">
          <div class="avatar placeholder">
            <div class={["w-12 rounded-box text-neutral-content", company.color_class]}>
              <span>{company.initials}</span>
            </div>
          </div>
          <h3 class="mt-3 font-bold">{company.name}</h3>
          <p class="text-sm text-base-content/60">{company.type}</p>
          <p class="text-sm text-base-content/70">{company.result}</p>
        </div>
      </div>
    </div>
    """
  end

  attr :reviews, :list, required: true

  def review_grid(assigns) do
    ~H"""
    <div class="grid gap-6 lg:grid-cols-3">
      <figure :for={review <- @reviews} class="card border border-base-300 bg-base-100 shadow-sm">
        <div class="card-body">
          <div class="rating rating-sm">
            <input
              :for={_star <- 1..5}
              type="radio"
              class="mask mask-star-2 bg-warning"
              checked
              disabled
            />
          </div>
          <blockquote class="mt-4 text-base-content/80">
            "{review.quote}"
          </blockquote>
          <figcaption class="mt-4">
            <div class="font-bold">{review.name}</div>
            <div class="text-sm text-base-content/60">{review.role}</div>
          </figcaption>
        </div>
      </figure>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, required: true

  def platform_demo(assigns) do
    ~H"""
    <div class="mx-auto grid max-w-6xl gap-6 lg:grid-cols-[1.15fr_0.85fr]">
      <div class="mockup-browser border border-base-300 bg-base-300 shadow-2xl">
        <div class="mockup-browser-toolbar">
          <div class="input border border-base-300 bg-base-100 text-xs">
            acme.localhost:4000/admin/collections
          </div>
        </div>
        <div class="bg-base-100 p-6">
          <div class="mb-5 flex flex-wrap items-center justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-primary">Tenant resolved</p>
              <h3 class="text-2xl font-black">{@title}</h3>
              <p class="text-sm text-base-content/60">{@subtitle}</p>
            </div>
            <div class="badge badge-success badge-lg">Plan: Pro</div>
          </div>

          <div class="grid gap-4 md:grid-cols-3">
            <div class="card border border-base-300 bg-base-200">
              <div class="card-body">
                <span class="text-sm text-base-content/60">Tenant DB</span>
                <strong>SQLite file</strong>
              </div>
            </div>
            <div class="card border border-base-300 bg-base-200">
              <div class="card-body">
                <span class="text-sm text-base-content/60">Admin path</span>
                <strong>/admin/collections</strong>
              </div>
            </div>
            <div class="card border border-base-300 bg-base-200">
              <div class="card-body">
                <span class="text-sm text-base-content/60">Isolation</span>
                <strong>Per tenant</strong>
              </div>
            </div>
          </div>

          <div class="mt-5 overflow-x-auto">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>Route</th>
                  <th>Context</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>acme.localhost</td>
                  <td>Tenant + plan</td>
                  <td><span class="badge badge-success">Ready</span></td>
                </tr>
                <tr>
                  <td>/platform/admin</td>
                  <td>Platform only</td>
                  <td><span class="badge badge-warning">Blocked</span></td>
                </tr>
                <tr>
                  <td>/admin/login</td>
                  <td>Tenant auth</td>
                  <td><span class="badge badge-info">Local</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="mockup-code min-h-full border border-base-300 bg-neutral text-neutral-content shadow-xl">
        <pre data-prefix="$"><code>mix phx.server</code></pre>
        <pre data-prefix=">"><code>resolve acme.localhost</code></pre>
        <pre data-prefix=">"><code>attach tenant context</code></pre>
        <pre data-prefix=">"><code>open tenant SQLite repo</code></pre>
        <pre data-prefix="✓" class="text-success"><code>serve isolated admin</code></pre>
      </div>
    </div>
    """
  end

  attr :items, :list, required: true

  def architecture_cards(assigns) do
    ~H"""
    <div class="grid gap-6 lg:grid-cols-3">
      <div :for={item <- @items} class="card border border-base-300 bg-base-100 shadow-sm">
        <div class="card-body">
          <div class={["badge", item.badge_class]}>{item.badge}</div>
          <h3 class="card-title mt-4">{item.title}</h3>
          <p class="text-base-content/70">{item.text}</p>
        </div>
      </div>
    </div>
    """
  end

  attr :plans, :list, required: true

  def pricing_tables(assigns) do
    ~H"""
    <div class="grid gap-6 lg:grid-cols-3">
      <article
        :for={plan <- @plans}
        class={[
          "card border bg-base-100 shadow-sm",
          plan.highlight && "border-primary shadow-primary/10",
          !plan.highlight && "border-base-300"
        ]}
      >
        <div class="card-body">
          <div class="flex items-center justify-between gap-4">
            <h3 class="card-title">{plan.name}</h3>
            <span :if={plan.highlight} class="badge badge-primary">Popular</span>
          </div>
          <p class="text-base-content/70">{plan.description}</p>
          <div class="mt-4">
            <span class="text-4xl font-black">{plan.price}</span>
            <span class="text-base-content/60">{plan.period}</span>
          </div>
          <ul class="mt-6 space-y-3">
            <li :for={feature <- plan.features} class="flex items-start gap-3">
              <.icon name="hero-check-circle" class="mt-0.5 size-5 text-success" />
              <span>{feature}</span>
            </li>
          </ul>
          <div class="card-actions mt-8">
            <a
              href={plan.href}
              class={["btn w-full", plan.highlight && "btn-primary", !plan.highlight && "btn-outline"]}
            >
              Choose {plan.name}
            </a>
          </div>
        </div>
      </article>
    </div>
    """
  end

  attr :quote, :string, required: true
  attr :name, :string, required: true
  attr :byline, :string, required: true

  def testimonial_section(assigns) do
    ~H"""
    <section class="px-4 py-16 sm:px-6 lg:px-8">
      <div class="mx-auto grid max-w-desktop overflow-hidden rounded-box border border-base-300 bg-base-200 lg:grid-cols-[0.8fr_1.2fr]">
        <div class="min-h-72 bg-neutral p-8 text-neutral-content">
          <div class="flex h-full flex-col justify-between">
            <img
              src={~p"/images/logo.png"}
              alt={MangoCMSWeb.Brand.name()}
              class="size-16 rounded-box bg-base-100 object-contain p-2 dark:hidden"
            />
            <img
              src={~p"/images/white-logo.png"}
              alt={MangoCMSWeb.Brand.name()}
              class="hidden size-16 rounded-box bg-base-100 object-contain p-2 dark:block"
            />
            <div>
              <p class="text-sm uppercase tracking-wide opacity-70">Operator story</p>
              <p class="mt-2 text-2xl font-black">
                Local-first operations without cross-tenant bleed.
              </p>
            </div>
          </div>
        </div>
        <figure class="p-8 sm:p-12">
          <blockquote class="text-2xl font-semibold leading-10 text-balance">
            "{@quote}"
          </blockquote>
          <figcaption class="mt-8">
            <div class="font-bold">{@name}</div>
            <div class="text-base-content/60">{@byline}</div>
          </figcaption>
        </figure>
      </div>
    </section>
    """
  end

  attr :id, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  slot :actions

  def cta_section(assigns) do
    ~H"""
    <section id={@id} class="px-4 py-16 sm:px-6 lg:px-8">
      <div class="hero mx-auto max-w-desktop rounded-box bg-primary text-primary-content">
        <div class="hero-content flex-col px-6 py-14 text-center">
          <h2 class="text-3xl font-black tracking-tight sm:text-5xl">{@title}</h2>
          <p class="max-w-2xl text-lg text-primary-content/80">{@subtitle}</p>
          <div :if={@actions != []} class="mt-4 flex flex-wrap justify-center gap-3">
            {render_slot(@actions)}
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :id, :string, default: nil
  attr :current_tenant, :any, default: nil
  attr :current_tenant_settings, :any, default: nil

  def landing_footer(assigns) do
    assigns =
      assigns
      |> assign(
        :brand_label,
        brand_label(assigns.current_tenant, assigns.current_tenant_settings)
      )
      |> assign(:brand_logo_url, TenantSettings.logo_url(assigns.current_tenant_settings))
      |> assign(
        :brand_dark_logo_url,
        TenantSettings.dark_logo_url(assigns.current_tenant_settings)
      )

    ~H"""
    <footer
      id={@id}
      class="footer footer-horizontal footer-center border-t border-base-300 bg-base-100 p-10 text-base-content"
    >
      <aside>
        <img
          src={@brand_logo_url || ~p"/images/logo.png"}
          alt={@brand_label}
          class="h-18 rounded-box object-contain dark:hidden"
        />
        <img
          src={@brand_dark_logo_url || @brand_logo_url || ~p"/images/white-logo.png"}
          alt={@brand_label}
          class="hidden h-18 rounded-box object-contain dark:block"
        />
        <p class="max-w-xl text-base-content/60">
          Multi-tenant Phoenix CMS infrastructure for local-first teams.
        </p>
      </aside>
      <nav class="grid grid-flow-col gap-4">
        <a href="#services" class="link link-hover">Services</a>
        <a href="#ai-chat" class="link link-hover">AI Chat</a>
        <a href="#plans" class="link link-hover">Plans</a>
        <a href="#reviews" class="link link-hover">Reviews</a>
      </nav>
      <aside>
        <p>{MangoCMSWeb.Brand.copyright()}</p>
      </aside>
    </footer>
    """
  end

  defp dashboard_href(nil, %MangoCMS.Platform.Accounts.User{} = user) do
    if Authorization.platform_admin_user?(user) do
      ~p"/platform/admin/dashboard"
    else
      ~p"/platform/dashboard"
    end
  end

  defp dashboard_href(_tenant, %MangoCMS.Tenant.Accounts.User{} = user) do
    if Authorization.tenant_admin_user?(user) do
      ~p"/admin/dashboard"
    else
      ~p"/dashboard"
    end
  end

  defp dashboard_href(_tenant, _user), do: ~p"/dashboard"

  defp profile_href(nil, %MangoCMS.Platform.Accounts.User{} = user) do
    if Authorization.platform_admin_user?(user) do
      ~p"/platform/admin/profile"
    else
      ~p"/platform/profile"
    end
  end

  defp profile_href(_tenant, %MangoCMS.Tenant.Accounts.User{} = user) do
    if Authorization.tenant_admin_user?(user) do
      ~p"/admin/profile"
    else
      ~p"/profile"
    end
  end

  defp profile_href(_tenant, _user), do: ~p"/profile"

  defp logout_href(nil, %MangoCMS.Platform.Accounts.User{} = user) do
    if Authorization.platform_admin_user?(user) do
      ~p"/platform/admin/logout"
    else
      ~p"/platform/logout"
    end
  end

  defp logout_href(_tenant, %MangoCMS.Tenant.Accounts.User{} = user) do
    if Authorization.tenant_admin_user?(user) do
      ~p"/admin/logout"
    else
      ~p"/logout"
    end
  end

  defp logout_href(_tenant, _user), do: ~p"/logout"

  defp login_href(nil), do: ~p"/platform/login"
  defp login_href(_tenant), do: ~p"/login"

  defp register_href(nil), do: ~p"/platform/register"
  defp register_href(_tenant), do: ~p"/register"

  defp brand_label(nil, _settings), do: MangoCMSWeb.Brand.name()
  defp brand_label(tenant, settings), do: TenantSettings.site_name(settings, tenant)

  defp account_initials(nil), do: nil
  defp account_initials(user), do: Layouts.user_initials(user)

  defp account_avatar_url(nil), do: nil
  defp account_avatar_url(user), do: Layouts.user_avatar_url(user)

  defp account_label(nil), do: "Account"
  defp account_label(user), do: Layouts.user_display_name(user)
end
