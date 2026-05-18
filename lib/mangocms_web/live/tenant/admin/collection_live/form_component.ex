defmodule MangoCMSWeb.Tenant.Admin.CollectionLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.Collections
  alias MangoCMS.Tenant.Collections.Collection

  @status_options Collection.status_options()
  @archetype_options Collection.archetype_options()
  @item_mode_options Collection.item_mode_options()
  @environment_options Collection.environment_options()
  @catalog_type_options [
    {"Service", "service"},
    {"Physical deliverable", "deliverable"},
    {"Digital download", "digital_download"}
  ]
  @catalog_optional_fields [
    {"description", "Description", "rich_text", "Long-form sales copy and internal notes."},
    {"cover_image", "Cover image", "image", "Primary image used by cards and sections."},
    {"sku", "SKU", "text", "Internal stock keeping unit."},
    {"inventory", "Inventory", "number", "Stock count for deliverables."},
    {"download_url", "Download URL", "url", "Secure asset link for digital downloads."}
  ]

  @impl true
  def render(%{action: :new} = assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>Create a collection from a content, catalog, or category blueprint.</:subtitle>
      </.header>

      <div class="mt-5 grid gap-2 sm:grid-cols-3">
        <div class={wizard_step_class(@wizard_step, 1)}>
          1. Collection type: {human_archetype(@selected_archetype)}
        </div>
        <div class={wizard_step_class(@wizard_step, 2)}>2. Setup path</div>
        <div class={wizard_step_class(@wizard_step, 3)}>3. Blueprint</div>
      </div>

      <.form
        for={@form}
        id="collection-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-6"
      >
        <input type="hidden" name="collection[archetype]" value={@selected_archetype} />
        <input type="hidden" name="collection[setup_path]" value={@setup_path} />

        <.collection_type_step
          :if={@wizard_step == 1}
          selected_archetype={@selected_archetype}
          myself={@myself}
        />
        <.setup_path_step
          :if={@wizard_step == 2}
          selected_archetype={@selected_archetype}
          setup_path={@setup_path}
          myself={@myself}
        />
        <.blueprint_step
          :if={@wizard_step == 3}
          form={@form}
          selected_archetype={@selected_archetype}
          catalog_type_options={@catalog_type_options}
          catalog_optional_fields={@catalog_optional_fields}
          selected_optional_fields={@selected_optional_fields}
          selected_catalog_type={@selected_catalog_type}
          archetype_options={@archetype_options}
          item_mode_options={@item_mode_options}
          environment_options={@environment_options}
          status_options={@status_options}
        />

        <div class="mt-6 flex items-center justify-between gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <div class="flex items-center gap-3">
            <button
              :if={@wizard_step > 1}
              id="collection-wizard-back"
              type="button"
              phx-target={@myself}
              phx-click="wizard_back"
              class="btn btn-ghost"
            >
              Back
            </button>
            <button
              :if={@wizard_step < 3}
              id="collection-wizard-next"
              type="button"
              phx-target={@myself}
              phx-click="wizard_next"
              class="btn btn-primary"
            >
              Continue
            </button>
            <.button
              :if={@wizard_step == 3}
              id="save-collection-button"
              variant="primary"
              phx-disable-with="Creating..."
            >
              Create collection
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
        <:subtitle>Collections define tenant-specific fields available to items.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="collection-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.blueprint_step
          form={@form}
          selected_archetype={@selected_archetype}
          catalog_type_options={@catalog_type_options}
          catalog_optional_fields={@catalog_optional_fields}
          selected_optional_fields={@selected_optional_fields}
          selected_catalog_type={@selected_catalog_type}
          archetype_options={@archetype_options}
          item_mode_options={@item_mode_options}
          environment_options={@environment_options}
          status_options={@status_options}
        />

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-collection-button" variant="primary" phx-disable-with="Saving...">
            Save collection
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  attr :selected_archetype, :string, required: true
  attr :myself, :any, required: true

  defp collection_type_step(assigns) do
    ~H"""
    <div id="collection-type-step" class="grid gap-4 md:grid-cols-3">
      <.wizard_card
        id="collection-type-content"
        title="Content Collection"
        description="Open canvas data for repeaters, sections, pages, and dynamic layouts."
        icon="hero-document-text"
        selected={@selected_archetype == "content"}
        myself={@myself}
        value="content"
      />
      <.wizard_card
        id="collection-type-catalog"
        title="Catalog Collection"
        description="Commerce-ready records with price, media, delivery, and inventory fields."
        icon="hero-shopping-bag"
        selected={@selected_archetype == "catalog"}
        myself={@myself}
        value="catalog"
      />
      <.wizard_card
        id="collection-type-category"
        title="Category Collection"
        description="Taxonomy and category-page data with hierarchy and sorting support."
        icon="hero-tag"
        selected={@selected_archetype == "category"}
        myself={@myself}
        value="category"
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :icon, :string, required: true
  attr :selected, :boolean, required: true
  attr :myself, :any, required: true
  attr :value, :string, required: true

  defp wizard_card(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-target={@myself}
      phx-click="select_archetype"
      phx-value-archetype={@value}
      class={[
        "rounded-lg border p-5 text-left transition hover:border-primary hover:bg-primary/5",
        @selected && "border-primary bg-primary/10"
      ]}
    >
      <.icon name={@icon} class="size-7 text-primary" />
      <h3 class="mt-4 font-semibold">{@title}</h3>
      <p class="mt-2 text-sm leading-6 text-base-content/60">{@description}</p>
    </button>
    """
  end

  attr :selected_archetype, :string, required: true
  attr :setup_path, :string, required: true
  attr :myself, :any, required: true

  defp setup_path_step(assigns) do
    ~H"""
    <div id="collection-setup-step" class="grid gap-4 md:grid-cols-3">
      <.setup_card
        id="setup-ai"
        value="ai"
        title="Create with AI"
        description="Describe the data you need and generate fields plus mock items."
        setup_path={@setup_path}
        myself={@myself}
        disabled
      />
      <.setup_card
        id="setup-scratch"
        value="scratch"
        title="Start from scratch"
        description="Create a clean schema and add fields manually."
        setup_path={@setup_path}
        myself={@myself}
      />
      <.setup_card
        id="setup-csv"
        value="csv"
        title="Import from CSV"
        description="Use uploaded headers and rows to initialize fields."
        setup_path={@setup_path}
        myself={@myself}
        disabled
      />
    </div>
    <p :if={@selected_archetype == "catalog"} class="mt-4 rounded-lg bg-info/10 p-4 text-sm text-info">
      Catalog collections always include required Name and Price fields. You can add optional catalog fields in the next step.
    </p>
    """
  end

  attr :id, :string, required: true
  attr :value, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :setup_path, :string, required: true
  attr :myself, :any, required: true
  attr :disabled, :boolean, default: false

  defp setup_card(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      disabled={@disabled}
      phx-target={@myself}
      phx-click="select_setup_path"
      phx-value-setup-path={@value}
      class={[
        "rounded-lg border p-5 text-left transition hover:border-primary hover:bg-primary/5",
        @setup_path == @value && "border-primary bg-primary/10",
        @disabled && "cursor-not-allowed opacity-50 hover:border-base-300 hover:bg-base-100"
      ]}
    >
      <div class="flex items-center justify-between gap-3">
        <h3 class="font-semibold">{@title}</h3>
        <span :if={@disabled} class="badge badge-ghost text-xs">Coming soon</span>
      </div>
      <p class="mt-2 text-sm leading-6 text-base-content/60">{@description}</p>
    </button>
    """
  end

  attr :form, :any, required: true
  attr :selected_archetype, :string, required: true
  attr :catalog_type_options, :list, required: true
  attr :catalog_optional_fields, :list, required: true
  attr :selected_optional_fields, :list, required: true
  attr :selected_catalog_type, :string, required: true
  attr :archetype_options, :list, required: true
  attr :item_mode_options, :list, required: true
  attr :environment_options, :list, required: true
  attr :status_options, :list, required: true

  defp blueprint_step(assigns) do
    ~H"""
    <div id="collection-blueprint-step" class="grid gap-5">
      <div class="grid gap-5 md:grid-cols-2">
        <.input
          field={@form[:name]}
          type="text"
          label="Collection name"
          placeholder={collection_name_placeholder(@selected_archetype)}
        />
        <.input
          field={@form[:slug]}
          type="text"
          label="Collection ID"
          placeholder={collection_slug_placeholder(@selected_archetype)}
        />
      </div>

      <.input
        field={@form[:description]}
        type="textarea"
        label="Description"
        rows="3"
        placeholder="Store and manage content to display anywhere on your site."
      />

      <input type="hidden" name="collection[archetype]" value={@selected_archetype} />

      <div class="grid gap-5 md:grid-cols-2">
        <div class="rounded-lg border border-base-300 bg-base-200 px-4 py-3">
          <p class="text-sm font-medium text-base-content/70">Collection type</p>
          <p class="mt-1 font-semibold">{human_archetype(@selected_archetype)}</p>
        </div>
        <.input
          field={@form[:item_mode]}
          type="select"
          label="Cardinality"
          options={@item_mode_options}
        />
        <.input
          field={@form[:environment]}
          type="select"
          label="Environment"
          options={@environment_options}
        />
        <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
      </div>

      <div
        :if={@selected_archetype == "catalog"}
        id="catalog-blueprint-options"
        class="rounded-lg border border-base-300 bg-base-200 p-5"
      >
        <h3 class="font-semibold">Catalog configuration</h3>
        <p class="mt-1 text-sm text-base-content/60">
          Name and Price are required catalog fields. System metadata fields are created automatically on every entry.
        </p>
        <div class="mt-4 grid gap-5 md:grid-cols-2">
          <.input
            id="collection_catalog_type"
            name="collection[catalog_type]"
            type="select"
            label="Catalog type"
            value={@selected_catalog_type}
            options={@catalog_type_options}
          />
          <div class="rounded-lg border border-base-300 bg-base-100 p-4 text-sm text-base-content/70">
            <p class="font-semibold text-base-content">Automatic system metadata</p>
            <p class="mt-2">
              Created At, Updated At, and Owner are tracked on entries and do not appear in Manage Fields.
            </p>
          </div>
        </div>
        <div class="mt-4 grid gap-3 md:grid-cols-2">
          <label class="flex gap-3 rounded-lg border border-primary/40 bg-primary/10 p-3">
            <input type="checkbox" checked disabled class="checkbox checkbox-sm mt-1" />
            <span>
              <span class="flex items-center gap-2 font-medium">
                Name <span class="badge badge-primary badge-sm">Required</span>
              </span>
              <span class="block text-sm text-base-content/60">
                Primary catalog label used for item titles and dynamic sections.
              </span>
            </span>
          </label>
          <label class="flex gap-3 rounded-lg border border-primary/40 bg-primary/10 p-3">
            <input type="checkbox" checked disabled class="checkbox checkbox-sm mt-1" />
            <span>
              <span class="flex items-center gap-2 font-medium">
                Price <span class="badge badge-primary badge-sm">Required</span>
              </span>
              <span class="block text-sm text-base-content/60">
                Numeric price field available for sorting, filtering, and product cards.
              </span>
            </span>
          </label>
          <label
            :for={{key, label, _type, description} <- @catalog_optional_fields}
            class="flex gap-3 rounded-lg border border-base-300 bg-base-100 p-3"
          >
            <input
              type="checkbox"
              name={"collection[optional_fields][#{key}]"}
              value="true"
              checked={key in @selected_optional_fields}
              class="checkbox checkbox-sm mt-1"
            />
            <span>
              <span class="block font-medium">{label}</span>
              <span class="block text-sm text-base-content/60">{description}</span>
            </span>
          </label>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{collection: collection} = assigns, socket) do
    changeset = Collections.change_collection(collection)
    archetype = collection.archetype || "content"

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:wizard_step, 1)
     |> assign(:selected_archetype, archetype)
     |> assign(:setup_path, "scratch")
     |> assign(:selected_catalog_type, catalog_type(collection))
     |> assign(:selected_optional_fields, [])
     |> assign_options()
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("select_archetype", %{"archetype" => archetype}, socket) do
    params =
      socket.assigns.form.params
      |> Map.put("archetype", archetype)
      |> maybe_put_catalog_defaults(archetype)

    {:noreply,
     socket
     |> assign(:selected_archetype, archetype)
     |> assign_form(changeset(socket, params))}
  end

  def handle_event("select_setup_path", %{"setup-path" => "scratch"} = params, socket) do
    setup_path = Map.fetch!(params, "setup-path")
    {:noreply, assign(socket, :setup_path, setup_path)}
  end

  def handle_event("select_setup_path", _params, socket), do: {:noreply, socket}

  def handle_event("wizard_next", _params, socket) do
    {:noreply, update(socket, :wizard_step, &min(&1 + 1, 3))}
  end

  def handle_event("wizard_back", _params, socket) do
    {:noreply, update(socket, :wizard_step, &max(&1 - 1, 1))}
  end

  def handle_event("validate", %{"collection" => collection_params}, socket) do
    params = normalize_collection_params(collection_params)

    {:noreply,
     socket
     |> assign(
       :selected_archetype,
       Map.get(params, "archetype", socket.assigns.selected_archetype)
     )
     |> assign(:setup_path, Map.get(collection_params, "setup_path", socket.assigns.setup_path))
     |> assign(
       :selected_catalog_type,
       Map.get(collection_params, "catalog_type", socket.assigns.selected_catalog_type)
     )
     |> assign(:selected_optional_fields, selected_optional_fields(collection_params))
     |> assign_form(changeset(socket, params))}
  end

  def handle_event("save", %{"collection" => collection_params}, socket) do
    save_collection(
      socket,
      socket.assigns.action,
      normalize_collection_params(collection_params)
    )
  end

  defp save_collection(socket, :edit, collection_params) do
    case Collections.update_collection(
           socket.assigns.tenant,
           socket.assigns.collection,
           collection_params
         ) do
      {:ok, collection} ->
        notify_parent({:saved, collection})

        {:noreply,
         socket
         |> put_flash(:info, "Collection updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_collection(socket, :new, collection_params) do
    case Collections.create_collection(socket.assigns.tenant, collection_params) do
      {:ok, collection} ->
        maybe_create_catalog_fields(socket, collection, collection_params)
        notify_parent({:saved, collection})

        {:noreply,
         socket
         |> put_flash(:info, "Collection created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp maybe_create_catalog_fields(socket, collection, %{"archetype" => "catalog"} = params) do
    fields =
      required_catalog_fields() ++ optional_catalog_fields(selected_optional_fields(params))

    Enum.each(fields, fn attrs ->
      Collections.create_collection_field(socket.assigns.tenant, collection, attrs)
    end)
  end

  defp maybe_create_catalog_fields(_socket, _collection, _params), do: :ok

  defp required_catalog_fields do
    [
      %{
        label: "Name",
        field_key: "name",
        field_type: "text",
        required: true,
        primary: true,
        system: false,
        visible: true,
        indexed: true,
        filterable: true,
        sortable: true,
        position: 10
      },
      %{
        label: "Price",
        field_key: "price",
        field_type: "number",
        required: true,
        system: false,
        visible: true,
        indexed: true,
        filterable: true,
        sortable: true,
        position: 20
      }
    ]
  end

  defp optional_catalog_fields(selected) do
    @catalog_optional_fields
    |> Enum.with_index(3)
    |> Enum.filter(fn {{key, _label, _type, _description}, _index} -> key in selected end)
    |> Enum.map(fn {{key, label, type, description}, index} ->
      %{
        label: label,
        field_key: key,
        field_type: type,
        required: false,
        system: false,
        visible: true,
        indexed: type in ~w(text image url number),
        filterable: type in ~w(text number),
        sortable: type == "number",
        help_text: description,
        position: index * 10
      }
    end)
  end

  defp normalize_collection_params(params) do
    optional_fields = selected_optional_fields(params)
    catalog_type = Map.get(params, "catalog_type", "service")

    settings =
      params
      |> Map.get("settings", %{})
      |> normalize_settings()
      |> Map.put("setup_path", Map.get(params, "setup_path", "scratch"))

    settings =
      if Map.get(params, "archetype") == "catalog" do
        settings
        |> Map.put("catalog_type", catalog_type)
        |> Map.put("optional_fields", optional_fields)
      else
        settings
      end

    params
    |> Map.drop(["catalog_type", "optional_fields", "setup_path"])
    |> Map.put("settings", settings)
  end

  defp maybe_put_catalog_defaults(params, "catalog") do
    params
    |> Map.put_new("name", "Catalog")
    |> Map.put_new("slug", "catalog")
    |> Map.put("item_mode", "multiple")
  end

  defp maybe_put_catalog_defaults(params, _archetype), do: params

  defp selected_optional_fields(%{"optional_fields" => fields}) when is_map(fields) do
    fields
    |> Enum.filter(fn {_key, value} -> value in [true, "true", "on", "1"] end)
    |> Enum.map(&elem(&1, 0))
  end

  defp selected_optional_fields(%{"settings" => %{"optional_fields" => fields}})
       when is_list(fields),
       do: fields

  defp selected_optional_fields(_params), do: []

  defp changeset(socket, params) do
    socket.assigns.collection
    |> Collections.change_collection(params)
    |> Map.put(:action, :validate)
  end

  defp assign_options(socket) do
    socket
    |> assign(:status_options, @status_options)
    |> assign(:archetype_options, @archetype_options)
    |> assign(:item_mode_options, @item_mode_options)
    |> assign(:environment_options, @environment_options)
    |> assign(:catalog_type_options, @catalog_type_options)
    |> assign(:catalog_optional_fields, @catalog_optional_fields)
  end

  defp normalize_settings(settings) when is_map(settings), do: settings
  defp normalize_settings(_settings), do: %{}

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp wizard_step_class(current_step, step) do
    [
      "rounded-lg border px-3 py-2 text-sm font-medium",
      if(current_step == step,
        do: "border-primary bg-primary/10 text-primary",
        else: "border-base-300 bg-base-200 text-base-content/60"
      )
    ]
  end

  defp human_archetype(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_archetype(_value), do: "Content"

  defp collection_name_placeholder("catalog"), do: "Service catalog"
  defp collection_name_placeholder("category"), do: "Blog categories"
  defp collection_name_placeholder(_archetype), do: "Team members"

  defp collection_slug_placeholder("catalog"), do: "service_catalog"
  defp collection_slug_placeholder("category"), do: "blog_categories"
  defp collection_slug_placeholder(_archetype), do: "team_members"

  defp catalog_type(%Collection{settings: %{"catalog_type" => catalog_type}})
       when is_binary(catalog_type),
       do: catalog_type

  defp catalog_type(_collection), do: "service"
end
