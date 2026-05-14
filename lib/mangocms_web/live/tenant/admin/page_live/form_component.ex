defmodule MangoCMSWeb.Tenant.Admin.PageLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.Pages
  alias MangoCMS.Tenant.Pages.Page

  @type_options Page.type_options()
  @status_options Page.status_options()

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>
          Pages are tenant-local and can contain fixed or dynamic sections.
        </:subtitle>
      </.header>

      <.form
        for={@form}
        id="page-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:title]} type="text" label="Title" placeholder="Home" />
          <.input field={@form[:slug]} type="text" label="Slug" placeholder="home" />
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:type]} type="select" label="Type" options={@type_options} />
          <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
        </div>

        <div class="rounded-lg border border-base-300 bg-base-200 p-4">
          <h3 class="font-semibold text-base-content">SEO</h3>
          <div class="mt-4 grid gap-5 md:grid-cols-2">
            <.input
              id="page_seo_title"
              name="page[seo][title]"
              type="text"
              label="SEO title"
              value={seo_value(@form, "title")}
              placeholder="Launch-ready websites"
            />
            <.input
              id="page_seo_description"
              name="page[seo][description]"
              type="textarea"
              label="SEO description"
              value={seo_value(@form, "description")}
              rows="3"
              placeholder="Short search result description."
            />
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-page-button" variant="primary" phx-disable-with="Saving...">
            Save page
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{page: page} = assigns, socket) do
    changeset = Pages.change_page(page)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:type_options, @type_options)
     |> assign(:status_options, @status_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"page" => page_params}, socket) do
    changeset =
      socket.assigns.page
      |> Pages.change_page(page_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"page" => page_params}, socket) do
    save_page(socket, socket.assigns.action, page_params)
  end

  defp save_page(socket, :edit, page_params) do
    case Pages.update_page(socket.assigns.tenant, socket.assigns.page, page_params) do
      {:ok, page} ->
        notify_parent({:saved, page})

        {:noreply,
         socket
         |> put_flash(:info, "Page updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_page(socket, :new, page_params) do
    case Pages.create_page(socket.assigns.tenant, page_params) do
      {:ok, page} ->
        notify_parent({:saved, page})

        {:noreply,
         socket
         |> put_flash(:info, "Page created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset),
    do: assign(socket, :form, to_form(changeset))

  defp seo_value(form, key) do
    case form[:seo].value do
      value when is_map(value) -> Map.get(value, key)
      _other -> nil
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
