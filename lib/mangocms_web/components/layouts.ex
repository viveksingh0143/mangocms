defmodule MangoCMSWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MangoCMSWeb, :html

  alias MangoCMS.Authorization
  alias MangoCMS.Tenant.Settings, as: TenantSettings

  @brand_name MangoCMSWeb.Brand.name()
  @admin_profile_email MangoCMSWeb.Brand.admin_profile_email()

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img
            src={~p"/images/logo.png"}
            alt={MangoCMSWeb.Brand.name()}
            class="size-12 rounded-box object-contain dark:hidden"
          />
          <img
            src={~p"/images/white-logo.png"}
            alt={MangoCMSWeb.Brand.name()}
            class="hidden size-12 rounded-box object-contain dark:block"
          />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc "Navigation for the platform admin layout."
  def platform_admin_nav(active, user \\ nil) do
    visible_admin_nav(
      [
        %{
          label: "Dashboard",
          href: ~p"/platform/admin/dashboard",
          current: active == :dashboard,
          permission: :view_dashboard
        },
        %{
          label: "Plans",
          href: ~p"/platform/admin/plans",
          current: active == :plans,
          permission: :manage_plans
        },
        %{
          label: "Tenants",
          href: ~p"/platform/admin/tenants",
          current: active == :tenants,
          permission: :manage_tenants
        },
        %{
          label: "Users",
          href: ~p"/platform/admin/users",
          current: active == :users,
          permission: :manage_users
        }
      ],
      :platform,
      user
    )
  end

  @doc "Navigation for the tenant admin layout."
  def tenant_admin_nav(active, user \\ nil) do
    visible_admin_nav(
      [
        %{
          label: "Dashboard",
          href: ~p"/admin/dashboard",
          current: active == :dashboard,
          permission: :view_dashboard
        },
        %{
          label: "Products",
          href: ~p"/admin/products",
          current: active == :products,
          permission: :manage_products
        },
        %{
          label: "Content",
          href: ~p"/admin/pages",
          current: active in [:pages, :content],
          children: [
            %{
              label: "Pages",
              href: ~p"/admin/pages",
              current: active == :pages,
              permission: :manage_pages
            },
            %{
              label: "Content Types",
              href: ~p"/admin/content-types",
              current: active == :content,
              permission: :manage_content
            }
          ]
        },
        %{
          label: "Users",
          href: ~p"/admin/users",
          current: active == :users,
          permission: :manage_users
        },
        %{
          label: "Settings",
          href: ~p"/admin/settings",
          current: active == :settings,
          permission: :manage_settings
        }
      ],
      :tenant,
      user
    )
  end

  defp visible_admin_nav(items, _scope, nil), do: items

  defp visible_admin_nav(items, scope, user) do
    items
    |> Enum.map(&filter_nav_item(&1, scope, user))
    |> Enum.reject(&is_nil/1)
  end

  defp filter_nav_item(item, scope, user) do
    children =
      item
      |> nav_children()
      |> Enum.map(&filter_nav_item(&1, scope, user))
      |> Enum.reject(&is_nil/1)

    cond do
      children != [] ->
        Map.put(item, :children, children)

      nav_item_allowed?(item, scope, user) ->
        item

      true ->
        nil
    end
  end

  defp nav_item_allowed?(item, scope, user) do
    case Map.get(item, :permission) do
      nil -> true
      permission -> Authorization.can?(user, scope, permission)
    end
  end

  @doc "Renders the platform admin layout with platform defaults."
  attr :id, :string, default: "platform-admin-layout"
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :current_user, :any, required: true
  attr :active, :atom, default: nil
  attr :nav_items, :list, default: nil
  attr :brand_label, :string, default: nil
  attr :brand_href, :string, default: nil
  attr :brand_logo_url, :string, default: nil
  attr :brand_dark_logo_url, :string, default: nil
  attr :profile_name, :string, default: nil
  attr :profile_email, :string, default: nil
  attr :profile_initials, :string, default: nil
  attr :profile_avatar_url, :string, default: nil
  attr :profile_href, :string, default: nil
  attr :logout_href, :string, default: nil

  slot :actions
  slot :inner_block, required: true

  def platform_admin(assigns) do
    assigns =
      assigns
      |> assign(
        :nav_items,
        assigns.nav_items || platform_admin_nav(assigns.active, assigns.current_user)
      )
      |> assign(:brand_label, assigns.brand_label || "Platform Admin")
      |> assign(:brand_href, assigns.brand_href || ~p"/platform/admin/dashboard")
      |> assign(:brand_logo_url, assigns.brand_logo_url)
      |> assign(:brand_dark_logo_url, assigns.brand_dark_logo_url)
      |> assign(:profile_name, assigns.profile_name || user_display_name(assigns.current_user))
      |> assign(:profile_email, assigns.profile_email || assigns.current_user.email)
      |> assign(
        :profile_initials,
        assigns.profile_initials || user_initials(assigns.current_user)
      )
      |> assign(
        :profile_avatar_url,
        assigns.profile_avatar_url || user_avatar_url(assigns.current_user)
      )
      |> assign(:profile_href, assigns.profile_href || ~p"/platform/admin/profile")
      |> assign(:logout_href, assigns.logout_href || ~p"/platform/admin/logout")

    ~H"""
    <.admin
      id={@id}
      flash={@flash}
      title={@title}
      subtitle={@subtitle}
      nav_items={@nav_items}
      brand_label={@brand_label}
      brand_href={@brand_href}
      brand_logo_url={@brand_logo_url}
      brand_dark_logo_url={@brand_dark_logo_url}
      profile_name={@profile_name}
      profile_email={@profile_email}
      profile_initials={@profile_initials}
      profile_avatar_url={@profile_avatar_url}
      profile_href={@profile_href}
      logout_href={@logout_href}
    >
      <:actions :for={action <- @actions}>
        {render_slot(action)}
      </:actions>
      {render_slot(@inner_block)}
    </.admin>
    """
  end

  @doc "Renders the tenant admin layout with tenant defaults."
  attr :id, :string, default: "tenant-admin-layout"
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :current_user, :any, required: true
  attr :current_tenant, :any, required: true
  attr :active, :atom, default: nil
  attr :nav_items, :list, default: nil
  attr :brand_label, :string, default: nil
  attr :brand_href, :string, default: nil
  attr :brand_logo_url, :string, default: nil
  attr :brand_dark_logo_url, :string, default: nil
  attr :profile_name, :string, default: nil
  attr :profile_email, :string, default: nil
  attr :profile_initials, :string, default: nil
  attr :profile_avatar_url, :string, default: nil
  attr :profile_href, :string, default: nil
  attr :logout_href, :string, default: nil
  attr :current_tenant_settings, :any, default: nil

  slot :actions
  slot :inner_block, required: true

  def tenant_admin(assigns) do
    assigns =
      assigns
      |> assign(
        :nav_items,
        assigns.nav_items || tenant_admin_nav(assigns.active, assigns.current_user)
      )
      |> assign(
        :brand_label,
        assigns.brand_label ||
          TenantSettings.site_name(assigns.current_tenant_settings, assigns.current_tenant)
      )
      |> assign(:brand_href, assigns.brand_href || ~p"/admin/dashboard")
      |> assign(
        :brand_logo_url,
        assigns.brand_logo_url || TenantSettings.logo_url(assigns.current_tenant_settings)
      )
      |> assign(
        :brand_dark_logo_url,
        assigns.brand_dark_logo_url ||
          TenantSettings.dark_logo_url(assigns.current_tenant_settings)
      )
      |> assign(:profile_name, assigns.profile_name || user_display_name(assigns.current_user))
      |> assign(:profile_email, assigns.profile_email || assigns.current_user.email)
      |> assign(
        :profile_initials,
        assigns.profile_initials || user_initials(assigns.current_user)
      )
      |> assign(
        :profile_avatar_url,
        assigns.profile_avatar_url || user_avatar_url(assigns.current_user)
      )
      |> assign(:profile_href, assigns.profile_href || ~p"/admin/profile")
      |> assign(:logout_href, assigns.logout_href || ~p"/admin/logout")

    ~H"""
    <.admin
      id={@id}
      flash={@flash}
      title={@title}
      subtitle={@subtitle}
      nav_items={@nav_items}
      brand_label={@brand_label}
      brand_href={@brand_href}
      brand_logo_url={@brand_logo_url}
      brand_dark_logo_url={@brand_dark_logo_url}
      profile_name={@profile_name}
      profile_email={@profile_email}
      profile_initials={@profile_initials}
      profile_avatar_url={@profile_avatar_url}
      profile_href={@profile_href}
      logout_href={@logout_href}
    >
      <:actions :for={action <- @actions}>
        {render_slot(action)}
      </:actions>
      {render_slot(@inner_block)}
    </.admin>
    """
  end

  @doc """
  Renders the stacked admin layout used by platform and tenant admin areas.

  This is a Phoenix-native conversion of the Tailwind stacked layout. It avoids
  Tailwind Plus custom elements and uses LiveView JS for the mobile menu and
  profile dropdown.
  """
  attr :id, :string, default: "admin-layout"
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :nav_items, :list, default: []
  attr :brand_label, :string, default: @brand_name
  attr :brand_href, :string, default: "/"
  attr :brand_logo_url, :string, default: nil
  attr :brand_dark_logo_url, :string, default: nil
  attr :profile_name, :string, default: "Admin"
  attr :profile_email, :string, default: @admin_profile_email
  attr :profile_initials, :string, default: "MC"
  attr :profile_avatar_url, :string, default: nil
  attr :profile_href, :string, default: nil
  attr :logout_href, :string, default: nil
  attr :login_href, :string, default: nil
  attr :register_href, :string, default: nil

  slot :actions
  slot :inner_block, required: true

  def admin(assigns) do
    assigns =
      assigns
      |> assign(
        :show_auth_links,
        not is_nil(assigns.login_href) or not is_nil(assigns.register_href)
      )
      |> assign(:profile_avatar_url, normalize_avatar_url(assigns.profile_avatar_url))
      |> assign(:mobile_menu_id, "#{assigns.id}-mobile-menu")
      |> assign(:mobile_menu_selector, "##{assigns.id}-mobile-menu")
      |> assign(:profile_menu_id, "#{assigns.id}-profile-menu")
      |> assign(:profile_menu_selector, "##{assigns.id}-profile-menu")

    ~H"""
    <div id={@id} class="min-h-full bg-base-200 text-base-content transition-colors">
      <nav class="sticky top-0 z-50 bg-gray-800 dark:bg-gray-800/50">
        <div class="mx-auto max-w-desktop px-4 sm:px-6 lg:px-8">
          <div class="flex h-16 items-center justify-between">
            <div class="flex items-center">
              <.link navigate={@brand_href} class="flex shrink-0 items-center gap-3">
                <img
                  src={@brand_logo_url || ~p"/images/logo.png"}
                  alt={@brand_label}
                  class="h-12 rounded-md bg-white p-1 dark:hidden"
                />
                <img
                  src={@brand_dark_logo_url || @brand_logo_url || ~p"/images/white-logo.png"}
                  alt={@brand_label}
                  class="hidden h-12 rounded-md bg-white p-1 dark:block"
                />
                <!-- <span class="hidden text-sm font-semibold text-white sm:block">{@brand_label}</span> -->
              </.link>
              <div class="hidden md:block">
                <div class="ml-10 flex items-baseline space-x-4">
                  <.link
                    :for={item <- @nav_items}
                    :if={nav_children(item) == []}
                    navigate={nav_href(item)}
                    aria-current={if(nav_current?(item), do: "page", else: nil)}
                    class={admin_nav_class(nav_current?(item), :desktop)}
                  >
                    {nav_label(item)}
                  </.link>
                  <div
                    :for={item <- @nav_items}
                    :if={nav_children(item) != []}
                    class="group relative"
                  >
                    <button
                      type="button"
                      aria-current={if(nav_current?(item), do: "page", else: nil)}
                      class={admin_nav_class(nav_current?(item), :desktop)}
                    >
                      <span>{nav_label(item)}</span>
                      <.icon name="hero-chevron-down" class="ml-1 inline size-3" />
                    </button>
                    <div class="absolute left-0 z-20 mt-2 hidden min-w-48 rounded-md bg-base-100 py-2 text-base-content shadow-lg shadow-base-content/10 outline-1 outline-base-300 group-focus-within:block group-hover:block">
                      <.link
                        :for={child <- nav_children(item)}
                        navigate={nav_href(child)}
                        aria-current={if(nav_current?(child), do: "page", else: nil)}
                        class={[
                          "block px-4 py-2 text-sm transition hover:bg-base-200 hover:text-base-content focus:bg-base-200 focus:text-base-content focus:outline-none",
                          nav_current?(child) && "font-semibold text-primary",
                          !nav_current?(child) && "text-base-content/80"
                        ]}
                      >
                        {nav_label(child)}
                      </.link>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div :if={@show_auth_links} class="flex items-center gap-2">
              <.theme_toggle />
              <.link
                :if={@login_href}
                id="admin-login-link"
                href={@login_href}
                class="btn btn-ghost btn-sm text-gray-200 hover:bg-white/5 hover:text-white"
              >
                Login
              </.link>
              <.link
                :if={@register_href}
                id="admin-register-link"
                href={@register_href}
                class="btn btn-primary btn-sm"
              >
                Register
              </.link>
            </div>

            <div :if={!@show_auth_links} class="hidden md:block">
              <div class="ml-4 flex items-center md:ml-6">
                <.theme_toggle />

                <button
                  type="button"
                  class="relative rounded-full p-1 text-gray-400 transition hover:text-white focus:outline-2 focus:outline-offset-2 focus:outline-indigo-500"
                >
                  <span class="absolute -inset-1.5"></span>
                  <span class="sr-only">View notifications</span>
                  <.icon name="hero-bell" class="size-6" />
                </button>

                <div class="ml-4 hidden min-w-0 text-right lg:block">
                  <div class="truncate text-sm font-medium text-white">{@profile_name}</div>
                  <div class="truncate text-xs text-gray-400">{@profile_email}</div>
                </div>

                <div class="relative ml-3">
                  <button
                    type="button"
                    id="admin-profile-menu-button"
                    phx-click={JS.toggle(to: @profile_menu_selector)}
                    class="relative flex max-w-xs items-center rounded-full focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
                  >
                    <span class="absolute -inset-1.5"></span>
                    <span class="sr-only">Open user menu</span>
                    <.profile_avatar
                      avatar_url={@profile_avatar_url}
                      initials={@profile_initials}
                      name={@profile_name}
                      class="size-8"
                      text_class="text-xs"
                    />
                  </button>

                  <div
                    id={@profile_menu_id}
                    phx-click-away={JS.hide(to: @profile_menu_selector)}
                    class="absolute right-0 z-10 mt-2 hidden w-48 origin-top-right rounded-md bg-base-100 py-1 text-base-content shadow-lg shadow-base-content/10 outline-1 outline-base-300 transition-colors"
                  >
                    <.link
                      :if={@profile_href}
                      navigate={@profile_href}
                      class="block px-4 py-2 text-sm text-base-content/80 transition hover:bg-base-200 hover:text-base-content focus:bg-base-200 focus:text-base-content focus:outline-hidden"
                    >
                      Your profile
                    </.link>
                    <.link
                      :if={@profile_href}
                      navigate={@profile_href}
                      class="block px-4 py-2 text-sm text-base-content/80 transition hover:bg-base-200 hover:text-base-content focus:bg-base-200 focus:text-base-content focus:outline-hidden"
                    >
                      Settings
                    </.link>
                    <.link
                      :if={@logout_href}
                      href={@logout_href}
                      method="delete"
                      class="block px-4 py-2 text-sm text-base-content/80 transition hover:bg-base-200 hover:text-base-content focus:bg-base-200 focus:text-base-content focus:outline-hidden"
                    >
                      Sign out
                    </.link>
                  </div>
                </div>
              </div>
            </div>

            <div :if={!@show_auth_links} class="-mr-2 flex md:hidden">
              <button
                type="button"
                id="admin-mobile-menu-button"
                phx-click={JS.toggle(to: @mobile_menu_selector)}
                class="relative inline-flex items-center justify-center rounded-md p-2 text-gray-400 transition hover:bg-white/5 hover:text-white focus:outline-2 focus:outline-offset-2 focus:outline-indigo-500"
              >
                <span class="absolute -inset-0.5"></span>
                <span class="sr-only">Open main menu</span>
                <.icon name="hero-bars-3" class="size-6" />
              </button>
            </div>
          </div>
        </div>

        <div id={@mobile_menu_id} class="hidden md:hidden">
          <div class="space-y-1 px-2 pt-2 pb-3 sm:px-3">
            <.link
              :for={item <- @nav_items}
              :if={nav_children(item) == []}
              navigate={nav_href(item)}
              aria-current={if(nav_current?(item), do: "page", else: nil)}
              class={admin_nav_class(nav_current?(item), :mobile)}
            >
              {nav_label(item)}
            </.link>
            <div :for={item <- @nav_items} :if={nav_children(item) != []}>
              <div class={admin_nav_class(nav_current?(item), :mobile)}>
                {nav_label(item)}
              </div>
              <div class="mt-1 space-y-1 pl-4">
                <.link
                  :for={child <- nav_children(item)}
                  navigate={nav_href(child)}
                  aria-current={if(nav_current?(child), do: "page", else: nil)}
                  class={admin_nav_class(nav_current?(child), :mobile)}
                >
                  {nav_label(child)}
                </.link>
              </div>
            </div>
          </div>
          <div class="border-t border-white/10 pt-4 pb-3">
            <div class="flex items-center px-5">
              <div class="shrink-0">
                <.profile_avatar
                  avatar_url={@profile_avatar_url}
                  initials={@profile_initials}
                  name={@profile_name}
                  class="size-10"
                  text_class="text-sm"
                />
              </div>
              <div class="ml-3 min-w-0">
                <div class="truncate text-base font-medium text-white">{@profile_name}</div>
                <div class="truncate text-sm font-medium text-gray-400">{@profile_email}</div>
              </div>
              <button
                type="button"
                class="relative ml-auto shrink-0 rounded-full p-1 text-gray-400 transition hover:text-white focus:outline-2 focus:outline-offset-2 focus:outline-indigo-500"
              >
                <span class="absolute -inset-1.5"></span>
                <span class="sr-only">View notifications</span>
                <.icon name="hero-bell" class="size-6" />
              </button>
            </div>
            <div class="mt-3 space-y-1 px-2">
              <.link
                :if={@profile_href}
                navigate={@profile_href}
                class="block rounded-md px-3 py-2 text-base font-medium text-gray-400 transition hover:bg-white/5 hover:text-white"
              >
                Your profile
              </.link>
              <.link
                :if={@profile_href}
                navigate={@profile_href}
                class="block rounded-md px-3 py-2 text-base font-medium text-gray-400 transition hover:bg-white/5 hover:text-white"
              >
                Settings
              </.link>
              <.link
                :if={@logout_href}
                href={@logout_href}
                method="delete"
                class="block rounded-md px-3 py-2 text-base font-medium text-gray-400 transition hover:bg-white/5 hover:text-white"
              >
                Sign out
              </.link>
            </div>
          </div>
        </div>
      </nav>

      <header class="sticky top-16 z-40 border-y border-base-300 bg-base-100 shadow-sm shadow-base-content/5 transition-colors">
        <div class="mx-auto flex max-w-desktop flex-col gap-4 px-4 py-4 sm:px-6 md:flex-row md:items-center md:justify-between lg:px-8">
          <div>
            <h1 class="text-lg/6 font-semibold text-base-content">{@title}</h1>
            <p :if={@subtitle} class="mt-1 text-sm text-base-content/60">{@subtitle}</p>
          </div>
          <div :if={@actions != []} class="flex items-center gap-3">
            {render_slot(@actions)}
          </div>
        </div>
      </header>

      <main>
        <div class="mx-auto max-w-desktop px-4 py-6 sm:px-6 lg:px-8">
          {render_slot(@inner_block)}
        </div>
      </main>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  attr :avatar_url, :string, default: nil
  attr :initials, :string, required: true
  attr :name, :string, required: true
  attr :class, :string, default: "size-8"
  attr :text_class, :string, default: "text-xs"

  defp profile_avatar(assigns) do
    ~H"""
    <img
      :if={@avatar_url}
      src={@avatar_url}
      alt={@name}
      class={["rounded-full object-cover outline -outline-offset-1 outline-white/10", @class]}
    />
    <span
      :if={!@avatar_url}
      class={[
        "grid place-items-center rounded-full bg-indigo-500 font-semibold text-white outline -outline-offset-1 outline-white/10",
        @class,
        @text_class
      ]}
    >
      {@initials}
    </span>
    """
  end

  defp nav_label(item), do: Map.fetch!(item, :label)

  defp nav_href(item) do
    case Map.get(item, :href) do
      nil -> item |> nav_children() |> List.first() |> nav_href()
      href -> href
    end
  end

  defp nav_current?(item) do
    Map.get(item, :current, false) or Enum.any?(nav_children(item), &nav_current?/1)
  end

  defp nav_children(item), do: Map.get(item, :children, [])

  def user_display_name(%{full_name: full_name} = user) when is_binary(full_name) do
    case String.trim(full_name) do
      "" -> user_email(user)
      name -> name
    end
  end

  def user_display_name(user), do: user_email(user)

  def user_initials(user) do
    user
    |> user_display_name()
    |> initials_from_text()
  end

  def user_avatar_url(%{avatar_url: avatar_url}), do: normalize_avatar_url(avatar_url)

  def user_avatar_url(_user), do: nil

  defp user_email(%{email: email}) when is_binary(email), do: email
  defp user_email(_user), do: "User"

  defp initials_from_text(text) when is_binary(text) do
    initials =
      text
      |> String.trim()
      |> String.split(~r/\s+/, trim: true)
      |> Enum.take(2)
      |> Enum.map_join("", &String.first/1)
      |> String.upcase()

    if initials == "", do: "U", else: initials
  end

  defp normalize_avatar_url(avatar_url) when is_binary(avatar_url) do
    case String.trim(avatar_url) do
      "" -> nil
      url -> url
    end
  end

  defp normalize_avatar_url(_avatar_url), do: nil

  defp admin_nav_class(true, :desktop),
    do: "rounded-md bg-gray-900 px-3 py-2 text-sm font-medium text-white dark:bg-gray-950/50"

  defp admin_nav_class(false, :desktop),
    do:
      "rounded-md px-3 py-2 text-sm font-medium text-gray-300 transition hover:bg-white/5 hover:text-white"

  defp admin_nav_class(true, :mobile),
    do: "block rounded-md bg-gray-900 px-3 py-2 text-base font-medium text-white"

  defp admin_nav_class(false, :mobile),
    do:
      "block rounded-md px-3 py-2 text-base font-medium text-gray-300 transition hover:bg-white/5 hover:text-white"

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        auto_dismiss={false}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        auto_dismiss={false}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
