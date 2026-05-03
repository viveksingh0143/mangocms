defmodule MangoCMSWeb.Platform.Admin.PlanLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Platform

  @currency_options [
    {"INR", "INR"},
    {"USD", "USD"},
    {"EUR", "EUR"},
    {"GBP", "GBP"},
    {"AUD", "AUD"},
    {"SGD", "SGD"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
      <.header>
        {@title}
        <:subtitle>Configure pricing, limits, availability, and premium plan capabilities.</:subtitle>
      </.header>

      <.form for={@form} id="plan-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:display_name]} type="text" label="Display name" placeholder="Growth" />
          <.input field={@form[:name]} type="text" label="Plan key" placeholder="growth" />
        </div>

        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          rows="3"
          placeholder="For growing editorial teams and high-traffic CMS sites."
        />

        <div class="grid gap-5 md:grid-cols-3">
          <.input field={@form[:price_monthly]} type="number" label="Monthly price" min="0" />
          <.input field={@form[:price_yearly]} type="number" label="Yearly price" min="0" />
          <.input field={@form[:currency]} type="select" label="Currency" options={@currency_options} />
        </div>

        <div class="grid gap-5 md:grid-cols-3">
          <.input
            field={@form[:yearly_discount_bps]}
            type="number"
            label="Yearly discount bps"
            min="0"
            max="10000"
          />
          <.input field={@form[:trial_period_days]} type="number" label="Trial days" min="0" />
          <.input field={@form[:sort_order]} type="number" label="Sort order" min="0" />
        </div>

        <div class="mt-6 grid gap-5 md:grid-cols-3">
          <.input field={@form[:max_pages]} type="number" label="Pages" min="1" />
          <.input field={@form[:max_storage_mb]} type="number" label="Storage MB" min="1" />
          <.input field={@form[:max_api_calls_per_day]} type="number" label="API calls/day" min="1" />
          <.input field={@form[:max_users]} type="number" label="Users" min="1" />
          <.input field={@form[:max_domains]} type="number" label="Domains" min="1" />
          <.input field={@form[:max_media_files]} type="number" label="Media files" min="1" />
        </div>

        <div class="mt-6 grid gap-3 rounded-lg border border-slate-200 bg-slate-50 p-4 sm:grid-cols-2 lg:grid-cols-3">
          <.input field={@form[:active]} type="checkbox" label="Active" />
          <.input field={@form[:is_public]} type="checkbox" label="Public" />
          <.input field={@form[:trial_requires_card]} type="checkbox" label="Trial requires card" />
          <.input field={@form[:custom_domain_support]} type="checkbox" label="Custom domains" />
          <.input field={@form[:api_access]} type="checkbox" label="API access" />
          <.input field={@form[:priority_support]} type="checkbox" label="Priority support" />
          <.input field={@form[:white_label]} type="checkbox" label="White label" />
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-plan-button" variant="primary" phx-disable-with="Saving...">
            Save plan
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{plan: plan} = assigns, socket) do
    changeset = Platform.change_plan_changeset(plan)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:currency_options, @currency_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"plan" => plan_params}, socket) do
    changeset =
      socket.assigns.plan
      |> Platform.change_plan_changeset(plan_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"plan" => plan_params}, socket) do
    save_plan(socket, socket.assigns.action, plan_params)
  end

  defp save_plan(socket, :edit, plan_params) do
    case Platform.update_plan(socket.assigns.plan, plan_params) do
      {:ok, plan} ->
        notify_parent({:saved, plan})

        {:noreply,
         socket
         |> put_flash(:info, "Plan updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_plan(socket, :new, plan_params) do
    case Platform.create_plan(plan_params) do
      {:ok, plan} ->
        notify_parent({:saved, plan})

        {:noreply,
         socket
         |> put_flash(:info, "Plan created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
