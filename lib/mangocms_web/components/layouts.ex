defmodule MangoCMSWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MangoCMSWeb, :html

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
          <img src={~p"/images/logo.png"} />
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
  def platform_admin_nav(active) do
    [
      %{label: "Plans", href: ~p"/platform/admin/plans", current: active == :plans},
      %{label: "Tenants", href: ~p"/platform/admin/tenants", current: active == :tenants}
    ]
  end

  @doc "Navigation for the tenant admin layout."
  def tenant_admin_nav(active) do
    [
      %{label: "Products", href: ~p"/admin/products", current: active == :products}
    ]
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
  attr :brand_label, :string, default: "MangoCMS"
  attr :brand_href, :string, default: "/"
  attr :profile_name, :string, default: "Admin"
  attr :profile_email, :string, default: "admin@mangocms.local"
  attr :profile_initials, :string, default: "MC"

  slot :actions
  slot :inner_block, required: true

  def admin(assigns) do
    assigns =
      assigns
      |> assign(:mobile_menu_id, "#{assigns.id}-mobile-menu")
      |> assign(:mobile_menu_selector, "##{assigns.id}-mobile-menu")
      |> assign(:profile_menu_id, "#{assigns.id}-profile-menu")
      |> assign(:profile_menu_selector, "##{assigns.id}-profile-menu")

    ~H"""
    <div id={@id} class="min-h-full bg-gray-100 dark:bg-gray-900">
      <nav class="bg-gray-800 dark:bg-gray-800/50">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div class="flex h-16 items-center justify-between">
            <div class="flex items-center">
              <.link navigate={@brand_href} class="flex shrink-0 items-center gap-3">
                <img
                  src={~p"/images/logo.png"}
                  alt={@brand_label}
                  class="h-12 rounded-md bg-white p-1"
                />
                <span class="hidden text-sm font-semibold text-white sm:block">{@brand_label}</span>
              </.link>
              <div class="hidden md:block">
                <div class="ml-10 flex items-baseline space-x-4">
                  <.link
                    :for={item <- @nav_items}
                    navigate={nav_href(item)}
                    aria-current={if(nav_current?(item), do: "page", else: nil)}
                    class={admin_nav_class(nav_current?(item), :desktop)}
                  >
                    {nav_label(item)}
                  </.link>
                </div>
              </div>
            </div>

            <div class="hidden md:block">
              <div class="ml-4 flex items-center md:ml-6">
                <button
                  type="button"
                  class="relative rounded-full p-1 text-gray-400 transition hover:text-white focus:outline-2 focus:outline-offset-2 focus:outline-indigo-500"
                >
                  <span class="absolute -inset-1.5"></span>
                  <span class="sr-only">View notifications</span>
                  <.icon name="hero-bell" class="size-6" />
                </button>

                <div class="relative ml-3">
                  <button
                    type="button"
                    id="admin-profile-menu-button"
                    phx-click={JS.toggle(to: @profile_menu_selector)}
                    class="relative flex max-w-xs items-center rounded-full focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
                  >
                    <span class="absolute -inset-1.5"></span>
                    <span class="sr-only">Open user menu</span>
                    <span class="grid size-8 place-items-center rounded-full bg-indigo-500 text-xs font-semibold text-white outline -outline-offset-1 outline-white/10">
                      {@profile_initials}
                    </span>
                  </button>

                  <div
                    id={@profile_menu_id}
                    phx-click-away={JS.hide(to: @profile_menu_selector)}
                    class="absolute right-0 z-10 mt-2 hidden w-48 origin-top-right rounded-md bg-white py-1 shadow-lg outline-1 outline-black/5 dark:bg-gray-800 dark:shadow-none dark:-outline-offset-1 dark:outline-white/10"
                  >
                    <a
                      href="#"
                      class="block px-4 py-2 text-sm text-gray-700 transition hover:bg-gray-100 focus:bg-gray-100 focus:outline-hidden dark:text-gray-300 dark:hover:bg-white/5 dark:focus:bg-white/5"
                    >
                      Your profile
                    </a>
                    <a
                      href="#"
                      class="block px-4 py-2 text-sm text-gray-700 transition hover:bg-gray-100 focus:bg-gray-100 focus:outline-hidden dark:text-gray-300 dark:hover:bg-white/5 dark:focus:bg-white/5"
                    >
                      Settings
                    </a>
                    <a
                      href="#"
                      class="block px-4 py-2 text-sm text-gray-700 transition hover:bg-gray-100 focus:bg-gray-100 focus:outline-hidden dark:text-gray-300 dark:hover:bg-white/5 dark:focus:bg-white/5"
                    >
                      Sign out
                    </a>
                  </div>
                </div>
              </div>
            </div>

            <div class="-mr-2 flex md:hidden">
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
              navigate={nav_href(item)}
              aria-current={if(nav_current?(item), do: "page", else: nil)}
              class={admin_nav_class(nav_current?(item), :mobile)}
            >
              {nav_label(item)}
            </.link>
          </div>
          <div class="border-t border-white/10 pt-4 pb-3">
            <div class="flex items-center px-5">
              <div class="shrink-0">
                <span class="grid size-10 place-items-center rounded-full bg-indigo-500 text-sm font-semibold text-white outline -outline-offset-1 outline-white/10">
                  {@profile_initials}
                </span>
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
              <a
                href="#"
                class="block rounded-md px-3 py-2 text-base font-medium text-gray-400 transition hover:bg-white/5 hover:text-white"
              >
                Your profile
              </a>
              <a
                href="#"
                class="block rounded-md px-3 py-2 text-base font-medium text-gray-400 transition hover:bg-white/5 hover:text-white"
              >
                Settings
              </a>
              <a
                href="#"
                class="block rounded-md px-3 py-2 text-base font-medium text-gray-400 transition hover:bg-white/5 hover:text-white"
              >
                Sign out
              </a>
            </div>
          </div>
        </div>
      </nav>

      <header class="relative bg-white shadow-sm dark:bg-gray-800 dark:shadow-none dark:after:pointer-events-none dark:after:absolute dark:after:inset-x-0 dark:after:inset-y-0 dark:after:bottom-0 dark:after:border-y dark:after:border-white/10">
        <div class="mx-auto flex max-w-7xl flex-col gap-4 px-4 py-4 sm:px-6 md:flex-row md:items-center md:justify-between lg:px-8">
          <div>
            <h1 class="text-lg/6 font-semibold text-gray-900 dark:text-white">{@title}</h1>
            <p :if={@subtitle} class="mt-1 text-sm text-gray-500 dark:text-gray-400">{@subtitle}</p>
          </div>
          <div :if={@actions != []} class="flex items-center gap-3">
            {render_slot(@actions)}
          </div>
        </div>
      </header>

      <main>
        <div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
          {render_slot(@inner_block)}
        </div>
      </main>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  defp nav_label(item), do: Map.fetch!(item, :label)
  defp nav_href(item), do: Map.fetch!(item, :href)
  defp nav_current?(item), do: Map.get(item, :current, false)

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
