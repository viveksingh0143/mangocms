defmodule MangoCMSWeb.Tenant.Admin.CollectionLive.FieldFormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.Collections
  alias MangoCMS.Tenant.Collections.CollectionField

  @field_type_options CollectionField.field_type_options()
  @length_validation_types ~w(string text rich_text rich_content url email color)

  @impl true
  def render(%{action: :new_field} = assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>Create a field through type, settings, validation, and default steps.</:subtitle>
      </.header>

      <.field_wizard_steps
        wizard_step={@field_wizard_step}
        selected_field_type={@selected_field_type}
      />

      <.form
        for={@form}
        id="collection-field-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-6"
      >
        <input type="hidden" name="collection_field[field_type]" value={@selected_field_type} />

        <.field_type_step
          :if={@field_wizard_step == 1}
          field_type_groups={@field_type_groups}
          field_type_query={@field_type_query}
          selected_field_type={@selected_field_type}
          myself={@myself}
        />

        <.field_settings_step
          :if={@field_wizard_step == 2}
          form={@form}
          selected_field_type={@selected_field_type}
          action={@action}
        />

        <.field_validations_step
          :if={@field_wizard_step == 3}
          form={@form}
          selected_field_type={@selected_field_type}
          options_text={@options_text}
          min_length={@min_length}
          max_length={@max_length}
        />

        <.field_default_step
          :if={@field_wizard_step == 4}
          selected_field_type={@selected_field_type}
          default_value={@default_value}
        />

        <div class="mt-6 flex items-center justify-between gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <div class="flex items-center gap-3">
            <button
              :if={@field_wizard_step > 1}
              id="field-wizard-back"
              type="button"
              phx-target={@myself}
              phx-click="wizard_back"
              class="btn btn-ghost"
            >
              Back
            </button>
            <button
              :if={@field_wizard_step < 4}
              id="field-wizard-next"
              type="button"
              phx-target={@myself}
              phx-click="wizard_next"
              class="btn btn-primary"
            >
              Continue
            </button>
            <.button
              :if={@field_wizard_step == 4}
              id="save-collection-field-button"
              variant="primary"
              phx-disable-with="Saving..."
            >
              Save field
            </.button>
          </div>
        </div>
      </.form>
    </section>
    """
  end

  def render(assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>Edit this field step by step. Field type is locked after creation.</:subtitle>
      </.header>

      <.field_wizard_steps
        wizard_step={@field_wizard_step}
        selected_field_type={@selected_field_type}
      />

      <.form
        for={@form}
        id="collection-field-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-6"
      >
        <input type="hidden" name="collection_field[field_type]" value={@selected_field_type} />

        <.field_type_locked_step
          :if={@field_wizard_step == 1}
          selected_field_type={@selected_field_type}
        />

        <.field_settings_step
          :if={@field_wizard_step == 2}
          form={@form}
          selected_field_type={@selected_field_type}
          action={@action}
        />
        <.field_validations_step
          :if={@field_wizard_step == 3}
          form={@form}
          selected_field_type={@selected_field_type}
          options_text={@options_text}
          min_length={@min_length}
          max_length={@max_length}
        />
        <.field_default_step
          :if={@field_wizard_step == 4}
          selected_field_type={@selected_field_type}
          default_value={@default_value}
        />

        <div class="mt-6 flex items-center justify-between gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <div class="flex items-center gap-3">
            <button
              :if={@field_wizard_step > 1}
              id="field-wizard-back"
              type="button"
              phx-target={@myself}
              phx-click="wizard_back"
              class="btn btn-ghost"
            >
              Back
            </button>
            <button
              :if={@field_wizard_step < 4}
              id="field-wizard-next"
              type="button"
              phx-target={@myself}
              phx-click="wizard_next"
              class="btn btn-primary"
            >
              Continue
            </button>
            <.button
              :if={@field_wizard_step == 4}
              id="save-collection-field-button"
              variant="primary"
              phx-disable-with="Saving..."
            >
              Save field
            </.button>
          </div>
        </div>
      </.form>
    </section>
    """
  end

  attr :wizard_step, :integer, required: true
  attr :selected_field_type, :string, required: true

  defp field_wizard_steps(assigns) do
    ~H"""
    <div class="mt-5 grid gap-2 md:grid-cols-4">
      <div class={field_wizard_step_class(@wizard_step, 1)}>
        1. Type: {field_type_label(@selected_field_type)}
      </div>
      <div class={field_wizard_step_class(@wizard_step, 2)}>2. Settings</div>
      <div class={field_wizard_step_class(@wizard_step, 3)}>3. Validations</div>
      <div class={field_wizard_step_class(@wizard_step, 4)}>4. Default value</div>
    </div>
    """
  end

  attr :field_type_groups, :list, required: true
  attr :field_type_query, :string, required: true
  attr :selected_field_type, :string, required: true
  attr :myself, :any, required: true

  defp field_type_step(assigns) do
    ~H"""
    <div id="field-type-step" class="rounded-lg border border-base-300 bg-base-200 p-4">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60">
          Choose field type
        </p>
        <label class="input input-bordered input-sm flex w-full items-center gap-2 md:w-72">
          <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
          <input
            id="field-type-search"
            type="search"
            value={@field_type_query}
            placeholder="Search field types"
            phx-target={@myself}
            phx-keyup="search_field_types"
          />
        </label>
      </div>
      <div class="mt-3 grid gap-4">
        <div :for={{group, fields} <- @field_type_groups}>
          <p class="mb-2 text-xs font-semibold text-base-content/50">{group}</p>
          <div class="grid gap-2 md:grid-cols-3">
            <button
              :for={{label, value} <- fields}
              id={"field-type-#{value}"}
              type="button"
              phx-target={@myself}
              phx-click="select_field_type"
              phx-value-field-type={value}
              class={[
                "rounded-lg border p-3 text-left text-sm transition hover:border-primary hover:bg-primary/5",
                @selected_field_type == value && "border-primary bg-primary/10"
              ]}
            >
              <span class="flex items-start gap-3">
                <span class="rounded-md bg-base-100 p-1 text-base-content/70">
                  <.icon name={field_type_icon(value)} class="size-4" />
                </span>
                <span>
                  <span class="block font-medium">{label}</span>
                  <span class="mt-1 block text-xs text-base-content/60">
                    {field_type_description(value)}
                  </span>
                </span>
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :selected_field_type, :string, required: true

  defp field_type_locked_step(assigns) do
    ~H"""
    <div id="field-type-step" class="rounded-lg border border-base-300 bg-base-200 p-5">
      <div class="flex items-start gap-3">
        <span class="rounded-lg bg-base-100 p-2">
          <.icon name={field_type_icon(@selected_field_type)} class="size-5 text-primary" />
        </span>
        <div>
          <p class="text-sm font-medium text-base-content/70">Field type</p>
          <p class="mt-1 font-semibold">{field_type_label(@selected_field_type)}</p>
          <p class="mt-1 text-sm text-base-content/60">
            {field_type_description(@selected_field_type)}. This cannot be changed after creation.
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :selected_field_type, :string, required: true
  attr :action, :atom, required: true

  defp field_settings_step(assigns) do
    ~H"""
    <div id="field-settings-step" class="grid gap-5">
      <div class="rounded-lg border border-base-300 bg-base-200 px-4 py-3">
        <p class="text-sm font-medium text-base-content/70">Field type</p>
        <p class="mt-1 font-semibold">{field_type_label(@selected_field_type)}</p>
        <p :if={@action == :edit_field} class="mt-1 text-xs text-base-content/60">
          Field type is locked after creation to protect existing entry data.
        </p>
      </div>

      <div class="grid gap-5 md:grid-cols-2">
        <.input field={@form[:label]} type="text" label="Field Name" placeholder="Price" />
        <.input
          field={@form[:field_key]}
          type="text"
          label="Field ID"
          placeholder="price"
          readonly={@action == :edit_field}
        />
      </div>

      <.input
        field={@form[:help_text]}
        type="textarea"
        label="Help text"
        rows="2"
        placeholder="Shown as guidance on item editing forms."
      />

      <div class="grid gap-5 md:grid-cols-2">
        <.input field={@form[:position]} type="number" label="Position" min="0" />
        <div class="rounded-lg border border-base-300 bg-base-200 p-4">
          <.input field={@form[:visible]} type="checkbox" label="Visible in table" />
          <.input
            :if={primary_field_type?(@selected_field_type)}
            field={@form[:primary]}
            type="checkbox"
            label="Primary field"
          />
          <label
            :if={primary_field_type?(@selected_field_type)}
            class="mt-2 flex items-center gap-3 text-sm"
          >
            <input type="hidden" name="collection_field[settings][slug_source]" value="false" />
            <input
              type="checkbox"
              name="collection_field[settings][slug_source]"
              value="true"
              checked={slug_source?(@form)}
              class="checkbox checkbox-sm"
            />
            <span>Use this field to update item slug</span>
          </label>
          <p :if={!primary_field_type?(@selected_field_type)} class="text-sm text-base-content/60">
            This field type cannot be used as the primary title field.
          </p>
        </div>
      </div>

      <div class="hidden">
        <input type="hidden" name="collection_field[system]" value="false" />
        <input
          :if={!primary_field_type?(@selected_field_type)}
          type="hidden"
          name="collection_field[primary]"
          value="false"
        />
        <input type="hidden" name="collection_field[required]" value="false" />
        <input
          id="collection_field_required_settings"
          type="checkbox"
          name="collection_field[required]"
          value="true"
          checked={truthy?(@form[:required].value)}
        />
        <input type="hidden" name="collection_field[unique]" value="false" />
        <input
          id="collection_field_unique_settings"
          type="checkbox"
          name="collection_field[unique]"
          value="true"
          checked={truthy?(@form[:unique].value)}
        />
        <input type="hidden" name="collection_field[indexed]" value="false" />
        <input
          id="collection_field_indexed_settings"
          type="checkbox"
          name="collection_field[indexed]"
          value="true"
          checked={truthy?(@form[:indexed].value)}
        />
        <input type="hidden" name="collection_field[filterable]" value="false" />
        <input
          id="collection_field_filterable_settings"
          type="checkbox"
          name="collection_field[filterable]"
          value="true"
          checked={truthy?(@form[:filterable].value)}
        />
        <input type="hidden" name="collection_field[sortable]" value="false" />
        <input
          id="collection_field_sortable_settings"
          type="checkbox"
          name="collection_field[sortable]"
          value="true"
          checked={truthy?(@form[:sortable].value)}
        />
      </div>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :selected_field_type, :string, required: true
  attr :options_text, :string, required: true
  attr :min_length, :string, required: true
  attr :max_length, :string, required: true

  defp field_validations_step(assigns) do
    ~H"""
    <div id="field-validations-step" class="grid gap-5">
      <div class="rounded-lg border border-base-300 bg-base-200 p-4">
        <p class="text-sm font-semibold">Validation and query flags</p>
        <p class="mt-1 text-sm text-base-content/60">
          Most validation behavior starts as simple on/off rules. Detailed limits can be added later per field type.
        </p>
        <div class="mt-4 grid gap-3 md:grid-cols-2">
          <.input field={@form[:required]} type="checkbox" label="Required" />
          <.input field={@form[:unique]} type="checkbox" label="Unique" />
          <.input field={@form[:indexed]} type="checkbox" label="Indexed" />
          <.input field={@form[:filterable]} type="checkbox" label="Filterable" />
          <.input field={@form[:sortable]} type="checkbox" label="Sortable" />
        </div>
      </div>

      <div
        :if={length_validation_type?(@selected_field_type)}
        id="field-length-validations-panel"
        class="rounded-lg border border-base-300 bg-base-200 p-4"
      >
        <p class="text-sm font-semibold">Length validation</p>
        <p class="mt-1 text-sm text-base-content/60">
          Optional minimum and maximum character limits for this field type.
        </p>
        <div class="mt-4 grid gap-4 md:grid-cols-2">
          <.input
            id="collection_field_min_length"
            name="collection_field[min_length]"
            type="number"
            label="Minimum length"
            value={@min_length}
            min="0"
          />
          <.input
            id="collection_field_max_length"
            name="collection_field[max_length]"
            type="number"
            label="Maximum length"
            value={@max_length}
            min="0"
          />
        </div>
      </div>

      <div :if={@selected_field_type == "select"} id="collection-field-options-panel">
        <.input
          id="collection_field_options_text"
          name="collection_field[options_text]"
          type="textarea"
          label="Select options"
          value={@options_text}
          rows="3"
          placeholder="Starter\nPro\nEnterprise"
        />
        <p class="-mt-1 text-xs text-base-content/60">Put one option per line.</p>
      </div>
    </div>
    """
  end

  attr :selected_field_type, :string, required: true
  attr :default_value, :string, required: true

  defp field_default_step(assigns) do
    ~H"""
    <div id="field-default-step" class="rounded-lg border border-base-300 bg-base-200 p-4">
      <p class="text-sm font-semibold">Default value</p>
      <p class="mt-1 text-sm text-base-content/60">
        Optional value applied when a new entry leaves this field empty.
      </p>
      <.input
        id="collection_field_default_value"
        name="collection_field[default_value]"
        type={default_input_type(@selected_field_type)}
        label="Default value"
        value={@default_value}
      />
    </div>
    """
  end

  @impl true
  def update(%{field: field} = assigns, socket) do
    changeset = Collections.change_collection_field(field)
    field_params = field_params(field)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:field_params, field_params)
     |> assign(:field_type_options, @field_type_options)
     |> assign(:field_type_query, "")
     |> assign(:field_type_groups, CollectionField.field_type_groups())
     |> assign(:options_text, options_text(field))
     |> assign(:default_value, default_value(field))
     |> assign(:min_length, setting_value(field, "min_length"))
     |> assign(:max_length, setting_value(field, "max_length"))
     |> assign(:selected_field_type, field.field_type || "string")
     |> assign(:field_wizard_step, 1)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"collection_field" => field_params}, socket) do
    params =
      field_params
      |> preserve_field_type(socket)
      |> merge_field_params(socket)
      |> normalize_field_params()

    changeset =
      socket.assigns.field
      |> Collections.change_collection_field(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:field_params, params)
     |> assign(:options_text, Map.get(field_params, "options_text", ""))
     |> assign(:default_value, Map.get(field_params, "default_value", ""))
     |> assign(:min_length, Map.get(field_params, "min_length", ""))
     |> assign(:max_length, Map.get(field_params, "max_length", ""))
     |> assign(:selected_field_type, Map.get(params, "field_type", "string"))
     |> assign_form(changeset)}
  end

  def handle_event("search_field_types", %{"value" => query}, socket) do
    {:noreply,
     socket
     |> assign(:field_type_query, query)
     |> assign(:field_type_groups, filtered_field_type_groups(query))}
  end

  def handle_event("wizard_next", _params, socket) do
    {:noreply, update(socket, :field_wizard_step, &min(&1 + 1, 4))}
  end

  def handle_event("wizard_back", _params, socket) do
    {:noreply, update(socket, :field_wizard_step, &max(&1 - 1, 1))}
  end

  def handle_event("select_field_type", _params, %{assigns: %{action: :edit_field}} = socket) do
    {:noreply, socket}
  end

  def handle_event("select_field_type", %{"field-type" => field_type}, socket) do
    params =
      socket.assigns.form.params
      |> merge_field_params(socket)
      |> Map.put("field_type", field_type)

    normalized_params = normalize_field_params(params)

    changeset =
      socket.assigns.field
      |> Collections.change_collection_field(normalized_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:selected_field_type, field_type)
     |> assign(:field_params, normalized_params)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"collection_field" => field_params}, socket) do
    params =
      field_params
      |> preserve_field_type(socket)
      |> merge_field_params(socket)
      |> normalize_field_params()

    save_field(socket, socket.assigns.action, params)
  end

  defp save_field(socket, :new_field, field_params) do
    case Collections.create_collection_field(
           socket.assigns.tenant,
           socket.assigns.collection,
           field_params
         ) do
      {:ok, field} ->
        notify_parent({:saved, field})

        {:noreply,
         socket
         |> put_flash(:info, "Collection field created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_field(socket, :edit_field, field_params) do
    case Collections.update_collection_field(
           socket.assigns.tenant,
           socket.assigns.field,
           field_params
         ) do
      {:ok, field} ->
        notify_parent({:saved, field})

        {:noreply,
         socket
         |> put_flash(:info, "Collection field updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp normalize_field_params(params) do
    field_type = Map.get(params, "field_type", "string")
    options_text = Map.get(params, "options_text", "")
    default_value = Map.get(params, "default_value", "")
    min_length = Map.get(params, "min_length", "")
    max_length = Map.get(params, "max_length", "")

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
      cond do
        field_type != "select" -> Map.delete(settings, "options")
        options == [] -> Map.delete(settings, "options")
        true -> Map.put(settings, "options", options)
      end

    settings =
      if default_value == "" do
        Map.delete(settings, "default_value")
      else
        Map.put(settings, "default_value", default_value)
      end

    settings =
      settings
      |> put_optional_integer("min_length", min_length)
      |> put_optional_integer("max_length", max_length)

    params
    |> Map.drop(["options_text", "default_value", "min_length", "max_length"])
    |> Map.put("settings", settings)
    |> Map.put("system", false)
    |> maybe_drop_primary(field_type)
  end

  defp merge_field_params(params, socket) do
    deep_merge(socket.assigns[:field_params] || %{}, params || %{})
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      deep_merge(left_value, right_value)
    end)
  end

  defp deep_merge(_left, right), do: right

  defp field_params(%CollectionField{} = field) do
    %{
      "label" => field.label || "",
      "field_key" => field.field_key || "",
      "field_type" => field.field_type || "string",
      "required" => field.required || false,
      "indexed" => field.indexed || false,
      "filterable" => field.filterable || false,
      "sortable" => field.sortable || false,
      "unique" => field.unique || false,
      "visible" => field.visible != false,
      "primary" => field.primary || false,
      "system" => false,
      "help_text" => field.help_text || "",
      "settings" => field.settings || %{},
      "position" => field.position || 0,
      "options_text" => options_text(field),
      "default_value" => default_value(field),
      "min_length" => setting_value(field, "min_length"),
      "max_length" => setting_value(field, "max_length")
    }
  end

  defp preserve_field_type(params, %{assigns: %{action: :edit_field, field: field}}) do
    Map.put(params, "field_type", field.field_type)
  end

  defp preserve_field_type(params, _socket), do: params

  defp normalize_settings(settings) when is_map(settings), do: settings
  defp normalize_settings(_settings), do: %{}

  defp options_text(%CollectionField{settings: settings}) when is_map(settings) do
    settings
    |> Map.get("options", [])
    |> case do
      options when is_list(options) -> Enum.join(options, "\n")
      _other -> ""
    end
  end

  defp options_text(_field), do: ""

  defp default_value(%CollectionField{settings: settings}) when is_map(settings) do
    settings
    |> Map.get("default_value", "")
    |> to_string()
  end

  defp default_value(_field), do: ""

  defp setting_value(%CollectionField{settings: settings}, key) when is_map(settings) do
    settings
    |> Map.get(key, "")
    |> to_string()
  end

  defp setting_value(_field, _key), do: ""

  defp field_wizard_step_class(current_step, step) do
    [
      "rounded-lg border px-3 py-2 text-sm font-medium",
      if(current_step == step,
        do: "border-primary bg-primary/10 text-primary",
        else: "border-base-300 bg-base-200 text-base-content/60"
      )
    ]
  end

  defp field_type_label(value) do
    @field_type_options
    |> Enum.find_value(value, fn {label, type} ->
      if type == value, do: label
    end)
  end

  defp field_type_icon(type) when type in ~w(string text rich_text rich_content),
    do: "hero-bars-3-bottom-left"

  defp field_type_icon(type) when type in ~w(url email), do: "hero-link"
  defp field_type_icon("number"), do: "hero-calculator"
  defp field_type_icon("boolean"), do: "hero-check-circle"
  defp field_type_icon("color"), do: "hero-swatch"

  defp field_type_icon(type) when type in ~w(reference multi_reference category tags select),
    do: "hero-tag"

  defp field_type_icon(type) when type in ~w(image gallery video audio document documents asset),
    do: "hero-photo"

  defp field_type_icon(type) when type in ~w(date datetime time), do: "hero-calendar-days"
  defp field_type_icon("address"), do: "hero-map-pin"
  defp field_type_icon(_type), do: "hero-cube"

  defp field_type_description("string"), do: "Single line text"
  defp field_type_description("text"), do: "Long plain text"
  defp field_type_description("rich_text"), do: "Formatted text"
  defp field_type_description("rich_content"), do: "Structured rich content"
  defp field_type_description("url"), do: "Web link"
  defp field_type_description("email"), do: "Email address"
  defp field_type_description("number"), do: "Numeric value"
  defp field_type_description("boolean"), do: "True or false"
  defp field_type_description("color"), do: "Color value"
  defp field_type_description("reference"), do: "Single relation"
  defp field_type_description("multi_reference"), do: "Multiple relations"
  defp field_type_description("tags"), do: "Tag list"
  defp field_type_description("category"), do: "Category value"
  defp field_type_description("select"), do: "Fixed choices"
  defp field_type_description("image"), do: "Single image"
  defp field_type_description("gallery"), do: "Image gallery"
  defp field_type_description("video"), do: "Video file"
  defp field_type_description("audio"), do: "Audio file"
  defp field_type_description("document"), do: "Single document"
  defp field_type_description("documents"), do: "Multiple documents"
  defp field_type_description("asset"), do: "Digital asset"
  defp field_type_description("date"), do: "Calendar date"
  defp field_type_description("datetime"), do: "Date and time"
  defp field_type_description("time"), do: "Time value"
  defp field_type_description("address"), do: "Location address"
  defp field_type_description("object"), do: "Nested object"
  defp field_type_description("array"), do: "Value list"
  defp field_type_description("json"), do: "Raw JSON"
  defp field_type_description(_type), do: "Custom value"

  defp default_input_type(type) when type in ~w(number), do: "number"
  defp default_input_type(type) when type in ~w(boolean), do: "checkbox"
  defp default_input_type(type) when type in ~w(date), do: "date"
  defp default_input_type(type) when type in ~w(datetime), do: "datetime-local"
  defp default_input_type(type) when type in ~w(email), do: "email"
  defp default_input_type(type) when type in ~w(url image video audio document asset), do: "url"
  defp default_input_type(_type), do: "text"

  defp truthy?(value), do: value in [true, "true", "1", "on"]

  defp primary_field_type?(type), do: CollectionField.primary_field_type?(type)
  defp length_validation_type?(type), do: type in @length_validation_types

  defp filtered_field_type_groups(query) do
    query = query |> to_string() |> String.downcase() |> String.trim()

    CollectionField.field_type_groups()
    |> Enum.map(fn {group, fields} ->
      fields =
        Enum.filter(fields, fn {label, value} ->
          haystack = "#{label} #{value} #{field_type_description(value)}" |> String.downcase()
          query == "" or String.contains?(haystack, query)
        end)

      {group, fields}
    end)
    |> Enum.reject(fn {_group, fields} -> fields == [] end)
  end

  defp put_optional_integer(settings, key, value) when value in [nil, ""],
    do: Map.delete(settings, key)

  defp put_optional_integer(settings, key, value) do
    case Integer.parse(to_string(value)) do
      {integer, ""} when integer >= 0 -> Map.put(settings, key, integer)
      _other -> Map.delete(settings, key)
    end
  end

  defp maybe_drop_primary(params, field_type) do
    if primary_field_type?(field_type) do
      params
    else
      Map.put(params, "primary", false)
    end
  end

  defp slug_source?(form) do
    case form[:settings].value do
      %{"slug_source" => value} -> truthy?(value)
      %{slug_source: value} -> truthy?(value)
      _other -> false
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
