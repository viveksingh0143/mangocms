defmodule MangoCMSWeb.Platform.Admin.PlanLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Platform
  alias MangoCMS.Platform.Plan

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :plans, Platform.list_plans())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit plan")
    |> assign(:plan, Platform.get_plan!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New plan")
    |> assign(:plan, %Plan{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Plans")
    |> assign(:plan, nil)
  end

  @impl true
  def handle_info({MangoCMSWeb.Platform.Admin.PlanLive.FormComponent, {:saved, plan}}, socket) do
    {:noreply, stream_insert(socket, :plans, plan)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    plan = Platform.get_plan!(id)
    {:ok, _} = Platform.delete_plan(plan)

    {:noreply, stream_delete(socket, :plans, plan)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin
      flash={@flash}
      title="Platform plans"
      subtitle="Administer billing plans, resource limits, and rollout visibility."
      nav_items={Layouts.platform_admin_nav(:plans)}
      brand_label="Platform Admin"
      brand_href={~p"/platform/admin/plans"}
      profile_name="Platform Admin"
      profile_email="platform@mangocms.local"
      profile_initials="PA"
    >
      <:actions>
        <.button id="new-plan-button" patch={~p"/platform/admin/plans/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> New plan
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Platform.Admin.PlanLive.FormComponent}
        id={@plan.id || :new}
        title={@page_title}
        action={@live_action}
        plan={@plan}
        patch={~p"/platform/admin/plans"}
      />

      <section class="mt-8 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
        <div id="plans" phx-update="stream" class="divide-y divide-slate-100">
          <div id="plans-empty" class="hidden only:block p-10 text-center text-sm text-slate-500">
            No plans have been created yet.
          </div>
          <div
            :for={{id, plan} <- @streams.plans}
            id={id}
            class="grid gap-4 p-5 transition hover:bg-slate-50 lg:grid-cols-[1.2fr_1fr_1fr_auto] lg:items-center"
          >
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <.link
                  navigate={~p"/platform/admin/plans/#{plan}"}
                  class="font-semibold text-slate-950 hover:text-orange-600"
                >
                  {plan.display_name}
                </.link>
                <span class="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-600">
                  {plan.name}
                </span>
              </div>
              <p class="mt-1 line-clamp-2 text-sm text-slate-500">{plan.description}</p>
            </div>

            <div class="text-sm text-slate-600">
              <p class="font-medium text-slate-900">
                {money(plan.price_monthly, plan.currency)} monthly
              </p>
              <p>{money(plan.price_yearly, plan.currency)} yearly</p>
            </div>

            <div class="flex flex-wrap gap-2">
              <span class={status_class(plan.active)}>
                {if(plan.active, do: "Active", else: "Inactive")}
              </span>
              <span class={status_class(plan.is_public)}>
                {if(plan.is_public, do: "Public", else: "Private")}
              </span>
            </div>

            <div class="flex items-center gap-3 lg:justify-end">
              <.link
                id={"show-plan-#{plan.id}"}
                navigate={~p"/platform/admin/plans/#{plan}"}
                class="btn btn-sm btn-ghost"
              >
                View
              </.link>
              <.link
                id={"edit-plan-#{plan.id}"}
                patch={~p"/platform/admin/plans/#{plan}/edit"}
                class="btn btn-sm btn-ghost"
              >
                Edit
              </.link>
              <button
                id={"delete-plan-#{plan.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={plan.id}
                data-confirm="Delete this plan?"
                class="btn btn-sm btn-ghost text-error"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </section>
    </Layouts.admin>
    """
  end

  defp money(amount, currency) when is_integer(amount) do
    "#{currency} #{:erlang.float_to_binary(amount / 100, decimals: 2)}"
  end

  defp money(_, currency), do: "#{currency} 0.00"

  defp status_class(true),
    do: "rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700"

  defp status_class(false),
    do: "rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600"
end
