defmodule MangoCMSWeb.Tenant.Admin.UserLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Authorization
  alias MangoCMS.Tenant.Accounts, as: TenantAccounts

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>
          Create tenant-local owners, admins, staff, customers, and members.
        </:subtitle>
      </.header>

      <.form
        for={@form}
        id="tenant-user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:full_name]} type="text" label="Full name" placeholder="Vivek Kumar" />
          <.input field={@form[:email]} type="email" label="Email" placeholder="vivek@example.com" />
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:role]} type="select" label="Role" options={@role_options} />
          <.input
            field={@form[:password]}
            type="password"
            label={if(@action == :new, do: "Password", else: "New password")}
            autocomplete="new-password"
          />
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:phone]} type="tel" label="Phone" />
          <.input field={@form[:avatar_url]} type="url" label="Avatar URL" />
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:locale]} type="text" label="Locale" placeholder="en" />
          <.input field={@form[:timezone]} type="text" label="Timezone" placeholder="UTC" />
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-tenant-user-button" variant="primary" phx-disable-with="Saving...">
            Save user
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = TenantAccounts.change_user(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:role_options, Authorization.tenant_role_options())
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> TenantAccounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case TenantAccounts.update_user(socket.assigns.tenant, socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "Tenant user updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case TenantAccounts.create_user(socket.assigns.tenant, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "Tenant user created successfully")
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
