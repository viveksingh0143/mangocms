defmodule MangoCMSWeb.Tenant.Admin.ContentTypeLive.FieldFormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.ContentEngine.ContentTypeField

  @field_type_options ContentTypeField.field_type_options()

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>Fields drive payload validation, filtering, sorting, and entry forms.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="content-type-field-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:label]} type="text" label="Label" placeholder="Price" />
          <.input field={@form[:field_key]} type="text" label="Field key" placeholder="price" />
        </div>

        <div class="grid gap-5 md:grid-cols-3">
          <.input
            field={@form[:field_type]}
            type="select"
            label="Field type"
            options={@field_type_options}
          />
          <.input field={@form[:position]} type="number" label="Position" min="0" />
          <div class="rounded-lg border border-base-300 bg-base-200 p-4">
            <.input field={@form[:required]} type="checkbox" label="Required" />
            <.input field={@form[:indexed]} type="checkbox" label="Indexed" />
            <.input field={@form[:filterable]} type="checkbox" label="Filterable" />
            <.input field={@form[:sortable]} type="checkbox" label="Sortable" />
          </div>
        </div>

        <.input
          id="content_type_field_options_text"
          name="content_type_field[options_text]"
          type="textarea"
          label="Select options"
          value={@options_text}
          rows="3"
          placeholder="Starter\nPro\nEnterprise"
        />
        <p class="-mt-1 text-xs text-base-content/60">
          Used when field type is select. Put one option per line.
        </p>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-content-field-button" variant="primary" phx-disable-with="Saving...">
            Save field
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{field: field} = assigns, socket) do
    changeset = ContentEngine.change_content_type_field(field)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:field_type_options, @field_type_options)
     |> assign(:options_text, options_text(field))
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"content_type_field" => field_params}, socket) do
    params = normalize_field_params(field_params)

    changeset =
      socket.assigns.field
      |> ContentEngine.change_content_type_field(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:options_text, Map.get(field_params, "options_text", ""))
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"content_type_field" => field_params}, socket) do
    save_field(socket, socket.assigns.action, normalize_field_params(field_params))
  end

  defp save_field(socket, :new_field, field_params) do
    case ContentEngine.create_content_type_field(
           socket.assigns.tenant,
           socket.assigns.content_type,
           field_params
         ) do
      {:ok, field} ->
        notify_parent({:saved, field})

        {:noreply,
         socket
         |> put_flash(:info, "Content field created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_field(socket, :edit_field, field_params) do
    case ContentEngine.update_content_type_field(
           socket.assigns.tenant,
           socket.assigns.field,
           field_params
         ) do
      {:ok, field} ->
        notify_parent({:saved, field})

        {:noreply,
         socket
         |> put_flash(:info, "Content field updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp normalize_field_params(params) do
    options_text = Map.get(params, "options_text", "")

    options =
      options_text
      |> String.split(~r/[\n,]/, trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    settings =
      params
      |> Map.get("settings", %{})
      |> normalize_settings()

    settings =
      if options == [] do
        Map.delete(settings, "options")
      else
        Map.put(settings, "options", options)
      end

    params
    |> Map.drop(["options_text"])
    |> Map.put("settings", settings)
  end

  defp normalize_settings(settings) when is_map(settings), do: settings
  defp normalize_settings(_settings), do: %{}

  defp options_text(%ContentTypeField{settings: settings}) when is_map(settings) do
    settings
    |> Map.get("options", [])
    |> case do
      options when is_list(options) -> Enum.join(options, "\n")
      _other -> ""
    end
  end

  defp options_text(_field), do: ""

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
