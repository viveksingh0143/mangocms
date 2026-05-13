defmodule MangoCMSWeb.Tenant.Admin.ContentTypeLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.ContentEngine.ContentType

  @status_options ContentType.status_options()

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>Content types define the tenant-specific fields available to entries.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="content-type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:name]} type="text" label="Name" placeholder="Services" />
          <.input field={@form[:slug]} type="text" label="Slug" placeholder="services" />
        </div>

        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          rows="3"
          placeholder="Reusable service records for dynamic cards and grids."
        />

        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-content-type-button" variant="primary" phx-disable-with="Saving...">
            Save content type
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{content_type: content_type} = assigns, socket) do
    changeset = ContentEngine.change_content_type(content_type)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:status_options, @status_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"content_type" => content_type_params}, socket) do
    changeset =
      socket.assigns.content_type
      |> ContentEngine.change_content_type(content_type_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"content_type" => content_type_params}, socket) do
    save_content_type(socket, socket.assigns.action, content_type_params)
  end

  defp save_content_type(socket, :edit, content_type_params) do
    case ContentEngine.update_content_type(
           socket.assigns.tenant,
           socket.assigns.content_type,
           content_type_params
         ) do
      {:ok, content_type} ->
        notify_parent({:saved, content_type})

        {:noreply,
         socket
         |> put_flash(:info, "Content type updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_content_type(socket, :new, content_type_params) do
    case ContentEngine.create_content_type(socket.assigns.tenant, content_type_params) do
      {:ok, content_type} ->
        notify_parent({:saved, content_type})

        {:noreply,
         socket
         |> put_flash(:info, "Content type created successfully")
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
