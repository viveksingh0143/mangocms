defmodule MangoCMSWeb.Platform.Admin.PlanLive.Show do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Platform
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_platform(socket, :manage_plans) do
      {:ok, socket} -> {:ok, socket}
      {:redirect, socket} -> {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    plan = Platform.get_plan!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:plan, plan)}
  end

  @impl true
  def handle_info({MangoCMSWeb.Platform.Admin.PlanLive.FormComponent, {:saved, plan}}, socket) do
    {:noreply, assign(socket, :plan, plan)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.platform_admin
      flash={@flash}
      title={@plan.display_name}
      subtitle={"Plan key: #{@plan.name}"}
      current_user={@current_user}
      active={:plans}
    >
      <:actions>
        <.button id="back-to-plans-button" navigate={~p"/platform/admin/plans"} class="btn btn-ghost">
          Back
        </.button>
        <.button
          id="edit-plan-button"
          patch={~p"/platform/admin/plans/#{@plan}/show/edit"}
          variant="primary"
        >
          <.icon name="hero-pencil-square" class="size-4" /> Edit
        </.button>
      </:actions>

      <.live_component
        :if={@live_action == :edit}
        module={MangoCMSWeb.Platform.Admin.PlanLive.FormComponent}
        id={@plan.id}
        title={@page_title}
        action={@live_action}
        plan={@plan}
        patch={~p"/platform/admin/plans/#{@plan}"}
      />

      <section id="plan-detail" class="mt-8 grid gap-4 md:grid-cols-2">
        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Pricing</h2>
          <dl class="mt-4 grid gap-4">
            <div>
              <dt class="text-sm text-base-content/60">Monthly</dt>
              <dd class="text-lg font-semibold text-base-content">
                {money(@plan.price_monthly, @plan.currency)}
              </dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Yearly</dt>
              <dd class="text-lg font-semibold text-base-content">
                {money(@plan.price_yearly, @plan.currency)}
              </dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Yearly discount</dt>
              <dd class="font-medium text-base-content/90">{@plan.yearly_discount_bps} bps</dd>
            </div>
          </dl>
        </div>

        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
            Availability
          </h2>
          <div class="mt-4 flex flex-wrap gap-2">
            <span class={status_class(@plan.active)}>
              {if(@plan.active, do: "Active", else: "Inactive")}
            </span>
            <span class={status_class(@plan.is_public)}>
              {if(@plan.is_public, do: "Public", else: "Private")}
            </span>
            <span class={status_class(@plan.trial_requires_card)}>
              {if(@plan.trial_requires_card, do: "Card trial", else: "No-card trial")}
            </span>
            <span class={status_class(@plan.custom_domain_support)}>
              {if(@plan.custom_domain_support, do: "Custom Domain Allowed", else: "No Custom Domain")}
            </span>
            <span class={status_class(@plan.api_access)}>
              {if(@plan.api_access, do: "Custom Domain Allowed", else: "No Custom Domain")}
            </span>
            <span class={status_class(@plan.priority_support)}>
              {if(@plan.priority_support, do: "Priority Support", else: "Standard Support")}
            </span>
            <span class={status_class(@plan.white_label)}>
              {if(@plan.white_label, do: "White Label", else: "No White Label")}
            </span>
          </div>
          <p class="mt-4 text-sm text-base-content/60">{@plan.description}</p>
        </div>

        <div class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors md:col-span-2">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Limits</h2>
          <dl class="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div>
              <dt class="text-sm text-base-content/60">Pages</dt>
              <dd class="font-semibold">{@plan.max_pages}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Storage MB</dt>
              <dd class="font-semibold">{@plan.max_storage_mb}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">API calls/day</dt>
              <dd class="font-semibold">{@plan.max_api_calls_per_day}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Users</dt>
              <dd class="font-semibold">{@plan.max_users}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Domains</dt>
              <dd class="font-semibold">{@plan.max_domains}</dd>
            </div>
            <div>
              <dt class="text-sm text-base-content/60">Media files</dt>
              <dd class="font-semibold">{@plan.max_media_files}</dd>
            </div>
          </dl>
        </div>
      </section>
    </Layouts.platform_admin>
    """
  end

  defp page_title(:show), do: "Show plan"
  defp page_title(:edit), do: "Edit plan"

  defp money(amount, currency) when is_integer(amount) do
    "#{currency} #{:erlang.float_to_binary(amount / 100, decimals: 2)}"
  end

  defp money(_, currency), do: "#{currency} 0.00"

  defp status_class(true),
    do:
      "rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:text-emerald-300"

  defp status_class(false),
    do: "rounded-full bg-base-200 px-2.5 py-1 text-xs font-semibold text-base-content/70"
end
