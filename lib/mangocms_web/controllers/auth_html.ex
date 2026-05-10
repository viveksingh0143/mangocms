defmodule MangoCMSWeb.AuthHTML do
  use MangoCMSWeb, :html

  embed_templates "auth_html/*"

  def admin_layout(assigns) do
    ~H"""
    <Layouts.admin
      flash={@flash}
      title={@title}
      subtitle={auth_subtitle(@context)}
      nav_items={[]}
      brand_label={auth_brand(@context)}
      brand_href={~p"/"}
      profile_name={auth_brand(@context)}
      profile_email={auth_profile_email(@context)}
      profile_initials={auth_initials(@context)}
      login_href={auth_login_href(@context)}
      register_href={auth_register_href(@context)}
    >
      {render_slot(@inner_block)}
    </Layouts.admin>
    """
  end

  attr :flash, :map, required: true
  attr :title, :string, required: true
  attr :context, :any, required: true
  attr :user, :any, required: true
  attr :back_path, :string, required: true
  attr :profile_action, :string, required: true

  slot :inner_block, required: true

  def profile_admin_layout(%{context: :platform} = assigns) do
    ~H"""
    <Layouts.platform_admin
      flash={@flash}
      title={@title}
      subtitle="Update profile information, account details, and password."
      current_user={@user}
      nav_items={[]}
      brand_href={@back_path}
      profile_href={@profile_action}
    >
      <:actions>
        <.button navigate={@back_path} class="btn btn-ghost">Back</.button>
      </:actions>

      {render_slot(@inner_block)}
    </Layouts.platform_admin>
    """
  end

  def profile_admin_layout(%{context: :platform_account} = assigns) do
    ~H"""
    <Layouts.admin
      flash={@flash}
      title={@title}
      subtitle="Update profile information, account details, and password."
      nav_items={[
        %{label: "Dashboard", href: ~p"/platform/dashboard", current: false}
      ]}
      brand_label={MangoCMSWeb.Brand.name()}
      brand_href={@back_path}
      profile_name={Layouts.user_display_name(@user)}
      profile_email={@user.email}
      profile_initials={Layouts.user_initials(@user)}
      profile_avatar_url={Layouts.user_avatar_url(@user)}
      profile_href={@profile_action}
      logout_href={~p"/platform/logout"}
    >
      <:actions>
        <.button navigate={@back_path} class="btn btn-ghost">Back</.button>
      </:actions>

      {render_slot(@inner_block)}
    </Layouts.admin>
    """
  end

  def profile_admin_layout(%{context: {tenant_context, tenant}} = assigns)
      when tenant_context in [:tenant_admin, :tenant_member] do
    logout_href =
      case tenant_context do
        :tenant_admin -> ~p"/admin/logout"
        :tenant_member -> ~p"/logout"
      end

    assigns =
      assigns
      |> assign(:tenant, tenant)
      |> assign(:logout_href, logout_href)

    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={@title}
      subtitle="Update profile information, account details, and password."
      current_user={@user}
      current_tenant={@tenant}
      nav_items={[]}
      brand_href={@back_path}
      profile_href={@profile_action}
      logout_href={@logout_href}
    >
      <:actions>
        <.button navigate={@back_path} class="btn btn-ghost">Back</.button>
      </:actions>

      {render_slot(@inner_block)}
    </Layouts.tenant_admin>
    """
  end

  attr :links, :list, required: true

  def sso_buttons(assigns) do
    ~H"""
    <div class="grid gap-3">
      <.link
        :for={link <- @links}
        href={link.href}
        class={[
          "btn w-full justify-center transition hover:opacity-90",
          provider_button_class(link.provider)
        ]}
      >
        <.provider_icon provider={link.provider} /> Login with {link.label}
      </.link>
    </div>
    """
  end

  slot :inner_block, required: true

  def auth_card(assigns) do
    ~H"""
    <div class="mx-auto max-w-md rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm shadow-base-content/5 transition-colors">
      {render_slot(@inner_block)}
    </div>
    """
  end

  def auth_divider(assigns) do
    ~H"""
    <div class="my-6 flex items-center gap-3">
      <div class="h-px flex-1 bg-base-300"></div>
      <span class="text-xs font-medium uppercase text-base-content/50">or</span>
      <div class="h-px flex-1 bg-base-300"></div>
    </div>
    """
  end

  def email_icon(assigns) do
    ~H"""
    <svg
      aria-label="Email icon"
      width="16"
      height="16"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
    >
      <g
        stroke-linejoin="round"
        stroke-linecap="round"
        stroke-width="2"
        fill="none"
        stroke="currentColor"
      >
        <rect width="20" height="16" x="2" y="4" rx="2"></rect>
        <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"></path>
      </g>
    </svg>
    """
  end

  attr :provider, :string, required: true

  def provider_icon(%{provider: "google"} = assigns) do
    ~H"""
    <svg
      aria-label="Google logo"
      width="16"
      height="16"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 512 512"
    >
      <g>
        <path d="m0 0H512V512H0" fill="#fff"></path>
        <path fill="#34a853" d="M153 292c30 82 118 95 171 60h62v48A192 192 0 0190 341"></path>
        <path fill="#4285f4" d="m386 400a140 175 0 0053-179H260v74h102q-7 37-38 57"></path>
        <path fill="#fbbc02" d="m90 341a208 200 0 010-171l63 49q-12 37 0 73"></path>
        <path fill="#ea4335" d="m153 219c22-69 116-109 179-50l55-54c-78-75-230-72-297 55"></path>
      </g>
    </svg>
    """
  end

  def provider_icon(%{provider: "outlook"} = assigns) do
    ~H"""
    <svg
      aria-label="Microsoft logo"
      width="16"
      height="16"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 512 512"
    >
      <path d="M96 96H247V247H96" fill="#f24f23"></path>
      <path d="M265 96V247H416V96" fill="#7eba03"></path>
      <path d="M96 265H247V416H96" fill="#3ca4ef"></path>
      <path d="M265 265H416V416H265" fill="#f9ba00"></path>
    </svg>
    """
  end

  def provider_icon(%{provider: "apple"} = assigns) do
    ~H"""
    <svg
      aria-label="Apple logo"
      width="16"
      height="16"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 1195 1195"
    >
      <path
        fill="white"
        d="M1006.933 812.8c-32 153.6-115.2 211.2-147.2 249.6-32 25.6-121.6 25.6-153.6 6.4-38.4-25.6-134.4-25.6-166.4 0-44.8 32-115.2 19.2-128 12.8-256-179.2-352-716.8 12.8-774.4 64-12.8 134.4 32 134.4 32 51.2 25.6 70.4 12.8 115.2-6.4 96-44.8 243.2-44.8 313.6 76.8-147.2 96-153.6 294.4 19.2 403.2zM802.133 64c12.8 70.4-64 224-204.8 230.4-12.8-38.4 32-217.6 204.8-230.4z"
      >
      </path>
    </svg>
    """
  end

  def provider_icon(assigns) do
    ~H"""
    <span class="size-4 rounded-full bg-current/20"></span>
    """
  end

  defp auth_subtitle(:platform), do: "Secure access for platform operators."
  defp auth_subtitle(:platform_account), do: "Create and manage your website account."
  defp auth_subtitle({:tenant_admin, tenant}), do: "Secure admin access for #{tenant.name}."
  defp auth_subtitle({:tenant_member, tenant}), do: "Secure access for #{tenant.name}."

  defp auth_brand(:platform), do: "Platform Admin"
  defp auth_brand(:platform_account), do: MangoCMSWeb.Brand.name()
  defp auth_brand({:tenant_admin, tenant}), do: "#{tenant.name} Admin"
  defp auth_brand({:tenant_member, tenant}), do: tenant.name

  defp auth_login_href(:platform), do: ~p"/platform/admin/login"
  defp auth_login_href(:platform_account), do: ~p"/platform/login"
  defp auth_login_href({:tenant_admin, _tenant}), do: ~p"/admin/login"
  defp auth_login_href({:tenant_member, _tenant}), do: ~p"/login"

  defp auth_register_href(:platform) do
    if MangoCMSWeb.PlatformRegistration.enabled?(), do: ~p"/platform/admin/register"
  end

  defp auth_register_href(:platform_account), do: ~p"/platform/register"
  defp auth_register_href({:tenant_admin, _tenant}), do: nil
  defp auth_register_href({:tenant_member, _tenant}), do: ~p"/register"

  defp auth_profile_email(:platform), do: MangoCMSWeb.Brand.platform_profile_email()
  defp auth_profile_email(:platform_account), do: MangoCMSWeb.Brand.platform_profile_email()
  defp auth_profile_email({_tenant_context, tenant}), do: tenant.domain

  defp auth_initials(context) do
    Layouts.user_initials(%{
      full_name: auth_brand(context),
      email: auth_profile_email(context)
    })
  end

  def email_button_class(extra_class \\ nil) do
    [
      "btn btn-primary w-full transition hover:bg-base-200",
      extra_class
    ]
  end

  def auth_link_class do
    "font-semibold text-primary transition hover:text-primary/80"
  end

  defp provider_button_class("google") do
    "border-[#e5e5e5] bg-white text-black hover:bg-white/90 dark:border-white/10"
  end

  defp provider_button_class("outlook") do
    "border-black bg-[#2F2F2F] text-white hover:bg-[#242424] dark:border-white/10"
  end

  defp provider_button_class("apple") do
    "border-black bg-black text-white hover:bg-neutral-900 dark:border-white/10"
  end

  defp provider_button_class(_provider) do
    "border-base-300 bg-base-100 text-base-content hover:bg-base-200"
  end
end
