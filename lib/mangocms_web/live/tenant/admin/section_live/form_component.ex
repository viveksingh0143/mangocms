defmodule MangoCMSWeb.Tenant.Admin.SectionLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.Pages

  @mode_options [{"Static", "static"}, {"Dynamic", "dynamic"}, {"Reference", "reference"}]

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>
          Sections are reusable blocks that can be inserted into pages and customized in the builder.
        </:subtitle>
      </.header>

      <.form
        for={@form}
        id="section-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:name]} type="text" label="Name" placeholder="Customer review slider" />
          <.input
            field={@form[:template_key]}
            type="text"
            label="Template key"
            placeholder="slider.customer_reviews"
          />
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <.input field={@form[:group_label]} type="text" label="Group" placeholder="Proof" />
          <.input field={@form[:mode]} type="select" label="Mode" options={@mode_options} />
        </div>

        <.input
          id="section_settings_json"
          name="section[settings_json]"
          type="textarea"
          label="Settings JSON"
          value={@settings_json}
          rows="5"
          placeholder={~s({"section_type":"slider","items_visible":{"desktop":3}})}
        />

        <.input
          id="section_source_config_json"
          name="section[source_config_json]"
          type="textarea"
          label="Source config JSON"
          value={@source_config_json}
          rows="5"
          placeholder={~s({"kind":"content_type","content_type_slug":"products"})}
        />

        <.input
          id="section_filters_json"
          name="section[filters_json]"
          type="textarea"
          label="Filters JSON"
          value={@filters_json}
          rows="4"
          placeholder={~s({"rules":[{"field":"rating","op":">=","value":4}]})}
        />

        <.input
          id="section_loop_settings_json"
          name="section[loop_settings_json]"
          type="textarea"
          label="Loop settings JSON"
          value={@loop_settings_json}
          rows="4"
          placeholder={~s({"enabled":true,"limit":6,"layout":"slider"})}
        />

        <.input
          id="section_content_tree_json"
          name="section[content_tree_json]"
          type="textarea"
          label="Content tree JSON"
          value={@content_tree_json}
          rows="10"
          placeholder="[]"
        />

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-section-button" variant="primary" phx-disable-with="Saving...">
            Save section
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{section: section} = assigns, socket) do
    changeset = Pages.change_section(section)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:mode_options, @mode_options)
     |> assign_json_fields(section)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"section" => params}, socket) do
    attrs = normalize_params(params)

    changeset =
      socket.assigns.section
      |> Pages.change_section(attrs)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_json_fields(params)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"section" => params}, socket) do
    save_section(socket, socket.assigns.action, normalize_params(params), params)
  end

  defp save_section(socket, :new, attrs, params) do
    case Pages.create_section(socket.assigns.tenant, attrs) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Section created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, socket |> assign_json_fields(params) |> assign_form(changeset)}
    end
  end

  defp save_section(socket, :edit, attrs, params) do
    case Pages.update_section(
           socket.assigns.tenant,
           socket.assigns.section,
           attrs,
           socket.assigns.current_user
         ) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Section updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, socket |> assign_json_fields(params) |> assign_form(changeset)}
    end
  end

  defp normalize_params(params) do
    params
    |> Map.drop([
      "settings_json",
      "source_config_json",
      "filters_json",
      "loop_settings_json",
      "content_tree_json"
    ])
    |> Map.put("settings", decode_map(params["settings_json"]))
    |> Map.put("source_config", decode_map(params["source_config_json"]))
    |> Map.put("filters", decode_map(params["filters_json"]))
    |> Map.put("loop_settings", decode_map(params["loop_settings_json"]))
    |> Map.put("content_tree", decode_list(params["content_tree_json"]))
  end

  defp assign_json_fields(socket, params) when is_map(params) do
    socket
    |> assign(:settings_json, Map.get(params, "settings_json", ""))
    |> assign(:source_config_json, Map.get(params, "source_config_json", ""))
    |> assign(:filters_json, Map.get(params, "filters_json", ""))
    |> assign(:loop_settings_json, Map.get(params, "loop_settings_json", ""))
    |> assign(:content_tree_json, Map.get(params, "content_tree_json", ""))
  end

  defp assign_json_fields(socket, section) do
    socket
    |> assign(:settings_json, encode_json(section.settings || %{}))
    |> assign(:source_config_json, encode_json(section.source_config || %{}))
    |> assign(:filters_json, encode_json(section.filters || %{}))
    |> assign(:loop_settings_json, encode_json(section.loop_settings || %{}))
    |> assign(:content_tree_json, encode_json(section.content_tree || []))
  end

  defp decode_map(value) do
    case Jason.decode(value || "") do
      {:ok, decoded} when is_map(decoded) -> decoded
      _other -> %{}
    end
  end

  defp decode_list(value) do
    case Jason.decode(value || "") do
      {:ok, decoded} when is_list(decoded) -> decoded
      _other -> []
    end
  end

  defp encode_json(value), do: Jason.encode!(value, pretty: true)

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))
  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
