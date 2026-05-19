defmodule MangoCMSWeb.Tenant.Admin.SectionLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.Collections
  alias MangoCMS.Tenant.Pages
  alias MangoCMS.Tenant.Pages.Section

  @impl true
  def render(%{action: :new} = assigns) do
    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>
          Create a reusable section from a template, then refine it in the visual builder.
        </:subtitle>
      </.header>

      <div class="mt-5 grid gap-2 sm:grid-cols-3">
        <div class={wizard_step_class(@wizard_step, "template")}>
          1. Section template: {human_template(@selected_template)}
        </div>
        <div class={wizard_step_class(@wizard_step, "details")}>2. Details</div>
        <div class={wizard_step_class(@wizard_step, "settings")}>3. Settings</div>
      </div>

      <.form
        for={@form}
        id="section-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-6"
      >
        <input type="hidden" name="section[template_preset]" value={@selected_template} />

        <.wizard_progress step={@wizard_step} />
        <.error_summary form={@form} />

        <.template_step
          :if={@wizard_step == "template"}
          selected_template={@selected_template}
          myself={@myself}
        />
        <.details_step
          :if={@wizard_step == "details"}
          form={@form}
          mode_options={@mode_options}
          new?
        />
        <.settings_step
          :if={@wizard_step == "settings"}
          settings={@settings}
          source_config={@source_config}
          loop_settings={@loop_settings}
          collection_options={@collection_options}
          selected_template={@selected_template}
        />

        <div class="mt-6 flex items-center justify-between gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <div class="flex items-center gap-3">
            <button
              :if={@wizard_step != "template"}
              id="section-wizard-back-button"
              type="button"
              phx-target={@myself}
              phx-click="previous_step"
              class="btn btn-ghost"
            >
              Back
            </button>
            <button
              :if={@wizard_step != "settings"}
              id="section-wizard-next-button"
              type="button"
              phx-target={@myself}
              phx-click="wizard_next"
              class="btn btn-primary"
            >
              Continue
            </button>
            <.button
              :if={@wizard_step == "settings"}
              id="save-section-button"
              name="section[_intent]"
              value="save"
              variant="primary"
              phx-disable-with="Creating..."
            >
              Create section
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
        <:subtitle>Update section metadata and data-source settings.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="section-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-6"
      >
        <.details_step form={@form} mode_options={@mode_options} new?={false} />
        <div class="mt-6">
          <.settings_step
            settings={@settings}
            source_config={@source_config}
            loop_settings={@loop_settings}
            collection_options={@collection_options}
            selected_template={@selected_template}
          />
        </div>

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

  attr :step, :string, required: true

  defp wizard_progress(assigns) do
    ~H"""
    <div class="mb-4 flex items-center justify-between rounded-lg border border-base-300 bg-base-200 px-4 py-3 text-sm">
      <span class="font-medium">Step {step_index(@step) + 1} of 3</span>
      <span class="text-base-content/60">{progress_label(@step)}</span>
    </div>
    """
  end

  attr :form, :any, required: true

  defp error_summary(assigns) do
    ~H"""
    <div
      :if={@form.source.action && @form.errors != []}
      id="section-form-errors"
      class="mb-4 rounded-lg border border-error/30 bg-error/10 p-4 text-sm text-error"
    >
      <p class="font-semibold">Please fix the highlighted section fields.</p>
      <ul class="mt-2 list-disc pl-5">
        <li :for={{field, {message, _opts}} <- @form.errors}>
          {human_field(field)} {message}
        </li>
      </ul>
    </div>
    """
  end

  attr :selected_template, :string, required: true
  attr :myself, :any, required: true

  defp template_step(assigns) do
    ~H"""
    <div id="section-template-step" class="grid gap-4 md:grid-cols-3">
      <.template_card
        :for={template <- section_templates()}
        id={"section-template-#{template.id}"}
        template={template}
        selected={@selected_template == template.id}
        myself={@myself}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :template, :map, required: true
  attr :selected, :boolean, required: true
  attr :myself, :any, required: true

  defp template_card(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-target={@myself}
      phx-click="select_template"
      phx-value-template={@template.id}
      class={[
        "rounded-lg border p-5 text-left transition hover:border-primary hover:bg-primary/5",
        @selected && "border-primary bg-primary/10"
      ]}
    >
      <.icon name={@template.icon} class="size-7 text-primary" />
      <div class="mt-4 flex items-start justify-between gap-3">
        <div>
          <h3 class="font-semibold">{@template.label}</h3>
          <p class="mt-2 text-sm leading-6 text-base-content/60">{@template.description}</p>
        </div>
        <span class="badge badge-ghost text-xs">{@template.mode}</span>
      </div>
    </button>
    """
  end

  attr :form, :any, required: true
  attr :mode_options, :list, required: true
  attr :new?, :boolean, default: false

  defp details_step(assigns) do
    ~H"""
    <div id="section-details-step" class="grid gap-5">
      <div class="grid gap-5 md:grid-cols-2">
        <.input
          field={@form[:name]}
          type="text"
          label="Section name"
          placeholder="Customer review slider"
        />
        <.input field={@form[:group_label]} type="text" label="Group" placeholder="Proof" />
        <.input
          :if={@new?}
          field={@form[:template_key]}
          type="text"
          label="Template key"
          placeholder="slider.customer_reviews"
        />
        <.input field={@form[:mode]} type="select" label="Mode" options={@mode_options} />
      </div>
      <div class="rounded-lg border border-base-300 bg-base-200 p-4 text-sm text-base-content/70">
        <p class="font-semibold text-base-content">Builder handoff</p>
        <p class="mt-2">
          After creation, open Builder to drag components, map fields, and tune the final visual layout.
        </p>
      </div>
    </div>
    """
  end

  attr :settings, :map, required: true
  attr :source_config, :map, required: true
  attr :loop_settings, :map, required: true
  attr :collection_options, :list, required: true
  attr :selected_template, :string, required: true

  defp settings_step(assigns) do
    ~H"""
    <div id="section-settings-step" class="grid gap-5">
      <div class="grid gap-5 md:grid-cols-2">
        <.input
          id="section-settings-section-type"
          name="section[settings][section_type]"
          type="select"
          label="Section type"
          value={setting_value(@settings, "section_type", @selected_template)}
          options={[
            {"Custom", "custom"},
            {"Hero", "hero"},
            {"CTA", "cta"},
            {"Slider", "slider"},
            {"Carousel", "carousel"},
            {"Gallery", "gallery"},
            {"Grid", "grid"}
          ]}
        />
        <.input
          id="section-settings-variant"
          name="section[settings][variant]"
          type="text"
          label="Variant"
          value={setting_value(@settings, "variant", "")}
        />
        <.input
          id="section-settings-items-visible"
          name="section[settings][items_visible_desktop]"
          type="number"
          label="Items visible on desktop"
          value={get_in(@settings, ["items_visible", "desktop"]) || 3}
        />
        <.input
          id="section-settings-transition"
          name="section[settings][transition]"
          type="select"
          label="Transition"
          value={setting_value(@settings, "transition", "slide")}
          options={[{"Slide", "slide"}, {"Fade", "fade"}, {"Snap", "snap"}, {"None", "none"}]}
        />
      </div>

      <div class="rounded-lg border border-base-300 bg-base-200 p-5">
        <h3 class="font-semibold">Data source</h3>
        <p class="mt-1 text-sm text-base-content/60">
          Fixed sections use their own content. Collection sections can preview and loop tenant records.
        </p>
        <div class="mt-4 grid gap-5 md:grid-cols-2">
          <.input
            id="section-source-kind"
            name="section[source_config][kind]"
            type="select"
            label="Data source"
            value={setting_value(@source_config, "kind", "fixed")}
            options={[
              {"Fixed content", "fixed"},
              {"Collection", "collection"},
              {"Catalog", "catalog"}
            ]}
          />
          <.input
            id="section-source-collection"
            name="section[source_config][collection_slug]"
            type="select"
            label="Collection"
            value={@source_config["collection_slug"] || ""}
            options={@collection_options}
          />
          <.input
            id="section-loop-enabled"
            name="section[loop_settings][enabled]"
            type="select"
            label="Loop records"
            value={bool_string(@loop_settings["enabled"])}
            options={[{"Disabled", "false"}, {"Enabled", "true"}]}
          />
          <.input
            id="section-loop-limit"
            name="section[loop_settings][limit]"
            type="number"
            label="Record limit"
            value={@loop_settings["limit"] || 6}
          />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{section: section} = assigns, socket) do
    changeset = Pages.change_section(section)
    selected_template = section.template_key || "custom"
    collections = Collections.list_collections(assigns.tenant)
    wizard_params = params_from_section(section, selected_template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:mode_options, Section.mode_options())
     |> assign(:wizard_step, "template")
     |> assign(:selected_template, selected_template)
     |> assign(:wizard_params, wizard_params)
     |> assign(:collections, collections)
     |> assign(:collection_options, collection_options(collections))
     |> assign_structured_fields(wizard_params)
     |> assign_form(changeset)}
  end

  def handle_event("set_step", %{"step" => step}, socket)
      when step in ~w(template details settings) do
    if step_reachable?(socket.assigns.wizard_step, step) do
      {:noreply, assign(socket, :wizard_step, step)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("previous_step", _params, socket) do
    {:noreply, assign(socket, :wizard_step, previous_step(socket.assigns.wizard_step))}
  end

  def handle_event("wizard_next", _params, socket) do
    attrs = socket.assigns.wizard_params
    changeset = Pages.change_section(socket.assigns.section, attrs)

    if wizard_step_valid?(socket.assigns.wizard_step, changeset) do
      {:noreply,
       socket
       |> assign_form(changeset)
       |> assign(:wizard_step, next_step(socket.assigns.wizard_step))}
    else
      {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
    end
  end

  def handle_event("select_template", %{"template" => template}, socket) do
    attrs = template_defaults(template)
    changeset = Pages.change_section(socket.assigns.section, attrs)

    {:noreply,
     socket
     |> assign(:selected_template, template)
     |> assign(:wizard_step, "details")
     |> assign(:wizard_params, attrs)
     |> assign_structured_fields(attrs)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"section" => params}, socket) do
    attrs = normalize_params(params, socket.assigns.section, socket.assigns.wizard_params)

    changeset =
      socket.assigns.section
      |> Pages.change_section(attrs)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:wizard_params, attrs)
     |> assign_structured_fields(attrs)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"section" => params}, socket) do
    attrs = normalize_params(params, socket.assigns.section, socket.assigns.wizard_params)
    intent = params["_intent"] || "save"

    cond do
      socket.assigns.action == :new and intent == "next" ->
        changeset = Pages.change_section(socket.assigns.section, attrs)

        if wizard_step_valid?(socket.assigns.wizard_step, changeset) do
          {:noreply,
           socket
           |> assign(:wizard_params, attrs)
           |> assign_structured_fields(attrs)
           |> assign_form(changeset)
           |> assign(:wizard_step, next_step(socket.assigns.wizard_step))}
        else
          {:noreply,
           socket
           |> assign(:wizard_params, attrs)
           |> assign_structured_fields(attrs)
           |> assign_form(Map.put(changeset, :action, :validate))}
        end

      true ->
        save_section(socket, socket.assigns.action, attrs, params)
    end
  end

  defp save_section(socket, :new, attrs, _params) do
    case Pages.create_section(socket.assigns.tenant, attrs) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Section created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:wizard_step, step_for_errors(changeset, socket.assigns.wizard_step))
         |> assign_structured_fields(attrs)
         |> assign_form(changeset)}
    end
  end

  defp save_section(socket, :edit, attrs, _params) do
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
        {:noreply, socket |> assign_structured_fields(attrs) |> assign_form(changeset)}
    end
  end

  defp normalize_params(params, %Section{} = section, existing_attrs) do
    template =
      params["template_preset"] || params["template_key"] || section.template_key || "custom"

    defaults = section_defaults(section, template) |> Map.merge(existing_attrs || %{})
    scalar_params = Map.drop(params, config_param_keys())

    defaults
    |> Map.merge(scalar_params)
    |> Map.drop(["_intent", "template_preset"])
    |> Map.put_new("template_key", template)
    |> Map.put_new("group_label", defaults["group_label"])
    |> Map.put_new("mode", defaults["mode"])
    |> Map.put("settings", merge_settings(defaults["settings"], params["settings"] || %{}))
    |> Map.put(
      "source_config",
      normalize_source_config(defaults["source_config"], params["source_config"] || %{})
    )
    |> Map.put("filters", params["filters"] || defaults["filters"] || %{})
    |> Map.put(
      "loop_settings",
      normalize_loop_settings(defaults["loop_settings"], params["loop_settings"] || %{})
    )
    |> Map.put("content_tree", params["content_tree"] || defaults["content_tree"] || [])
  end

  defp section_defaults(%Section{id: nil}, template), do: template_defaults(template)

  defp section_defaults(%Section{} = section, template) do
    template_defaults(template)
    |> Map.merge(%{
      "template_key" => section.template_key || template,
      "group_label" => section.group_label || "General",
      "mode" => section.mode || "fixed",
      "settings" => section.settings || %{},
      "source_config" => section.source_config || %{},
      "filters" => section.filters || %{},
      "loop_settings" => section.loop_settings || %{"enabled" => false, "limit" => 6},
      "content_tree" => section.content_tree || []
    })
  end

  defp params_from_section(%Section{id: nil}, template), do: template_defaults(template)

  defp params_from_section(%Section{} = section, template) do
    section_defaults(section, template)
    |> Map.merge(%{
      "name" => section.name,
      "template_key" => section.template_key || template,
      "group_label" => section.group_label || "General",
      "mode" => section.mode || "fixed"
    })
  end

  defp assign_structured_fields(socket, %Section{} = section) do
    socket
    |> assign(:settings, section.settings || %{})
    |> assign(:source_config, section.source_config || %{})
    |> assign(:filters, section.filters || %{})
    |> assign(:loop_settings, section.loop_settings || %{})
  end

  defp assign_structured_fields(socket, attrs) when is_map(attrs) do
    socket
    |> assign(:settings, attrs["settings"] || attrs[:settings] || %{})
    |> assign(:source_config, attrs["source_config"] || attrs[:source_config] || %{})
    |> assign(:filters, attrs["filters"] || attrs[:filters] || %{})
    |> assign(:loop_settings, attrs["loop_settings"] || attrs[:loop_settings] || %{})
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))
  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp config_param_keys do
    [
      "_intent",
      "template_preset",
      "settings",
      "source_config",
      "filters",
      "loop_settings",
      "content_tree"
    ]
  end

  defp wizard_step_valid?("template", _changeset), do: true

  defp wizard_step_valid?("details", changeset) do
    detail_fields = [:name, :template_key, :group_label, :mode]

    changeset.valid? or
      changeset.errors
      |> Keyword.keys()
      |> Enum.all?(&(&1 not in detail_fields))
  end

  defp wizard_step_valid?(_step, changeset), do: changeset.valid?

  defp step_for_errors(changeset, current_step) do
    error_fields = Keyword.keys(changeset.errors)

    cond do
      Enum.any?(error_fields, &(&1 in [:name, :template_key, :group_label, :mode])) -> "details"
      true -> current_step
    end
  end

  defp step_reachable?(current_step, requested_step) do
    step_index(requested_step) <= step_index(current_step)
  end

  defp next_step("template"), do: "details"
  defp next_step("details"), do: "settings"
  defp next_step(step), do: step

  defp previous_step("settings"), do: "details"
  defp previous_step("details"), do: "template"
  defp previous_step(step), do: step

  defp step_index("template"), do: 0
  defp step_index("details"), do: 1
  defp step_index("settings"), do: 2
  defp step_index(_step), do: 0

  defp progress_label("template"), do: "Choose the starter section template."
  defp progress_label("details"), do: "Name the section and set its group."
  defp progress_label("settings"), do: "Configure source, loop, and display behavior."
  defp progress_label(_step), do: "Create section."

  defp human_field(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp section_templates do
    [
      %{
        id: "custom",
        label: "Custom",
        description: "Blank section canvas for fully custom composition.",
        mode: "fixed",
        icon: "hero-squares-plus"
      },
      %{
        id: "hero",
        label: "Hero",
        description: "Headline, supporting copy, action, and media starter.",
        mode: "fixed",
        icon: "hero-photo"
      },
      %{
        id: "cta",
        label: "CTA",
        description: "Action-focused banner with concise copy and button.",
        mode: "fixed",
        icon: "hero-cursor-arrow-rays"
      },
      %{
        id: "slider",
        label: "Slider",
        description: "Collection-powered cards for reviews, products, or posts.",
        mode: "collection",
        icon: "hero-arrow-path-rounded-square"
      },
      %{
        id: "gallery",
        label: "Gallery",
        description: "Image-forward collection grid with reusable mappings.",
        mode: "collection",
        icon: "hero-rectangle-stack"
      }
    ]
  end

  defp wizard_step_class(current_step, step) do
    [
      "rounded-lg border px-4 py-3 text-sm font-medium",
      current_step == step && "border-primary bg-primary/10 text-primary",
      current_step != step && "border-base-300 bg-base-200 text-base-content/60"
    ]
  end

  defp human_template(template) when is_binary(template) do
    template
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp human_template(_template), do: "Custom"

  defp template_defaults(template) do
    template = template || "custom"

    %{
      "template_key" => template,
      "group_label" => template |> String.replace("_", " ") |> String.capitalize(),
      "mode" => if(template in ["slider", "gallery"], do: "collection", else: "fixed"),
      "settings" => %{
        "section_type" => template,
        "variant" => "default",
        "transition" => "slide",
        "items_visible" => %{"desktop" => if(template == "gallery", do: 4, else: 3)}
      },
      "source_config" => %{
        "kind" => if(template in ["slider", "gallery"], do: "collection", else: "fixed")
      },
      "filters" => %{"rules" => []},
      "loop_settings" => %{
        "enabled" => template in ["slider", "gallery"],
        "limit" => if(template == "gallery", do: 8, else: 6),
        "layout" => template,
        "as" => "item"
      },
      "content_tree" => template_tree(template)
    }
  end

  defp template_tree("hero") do
    [
      container_node("section", "py-16")
      |> Map.put("children", [
        container_node("row", "mx-auto grid max-w-7xl gap-8 md:grid-cols-2")
        |> Map.put("children", [
          container_node("column", "grid content-center gap-4")
          |> Map.put("children", [
            leaf_node("heading", %{"text" => "Build with MangoCMS"}, "text-5xl font-bold"),
            leaf_node(
              "paragraph",
              %{"text" => "A fast, tenant-local website section."},
              "text-lg text-base-content/70"
            ),
            leaf_node(
              "button",
              %{"text" => "Get started", "href" => "#"},
              "btn btn-primary w-fit"
            )
          ]),
          container_node("column", "grid")
          |> Map.put("children", [
            leaf_node(
              "image",
              %{"src" => "", "alt" => ""},
              "aspect-video rounded-lg object-cover"
            )
          ])
        ])
      ])
    ]
  end

  defp template_tree("cta") do
    [
      container_node("section", "py-12")
      |> Map.put("children", [
        container_node("row", "mx-auto max-w-5xl rounded-lg bg-base-200 p-8 text-center")
        |> Map.put("children", [
          container_node("column", "grid justify-items-center gap-4")
          |> Map.put("children", [
            leaf_node("heading", %{"text" => "Ready to publish?"}, "text-3xl font-bold"),
            leaf_node(
              "paragraph",
              %{"text" => "Create a reusable call to action."},
              "text-base-content/70"
            ),
            leaf_node("button", %{"text" => "Open page", "href" => "#"}, "btn btn-primary")
          ])
        ])
      ])
    ]
  end

  defp template_tree(template) when template in ["slider", "gallery"] do
    [
      container_node("section", "py-12")
      |> Map.put("children", [
        container_node("row", "mx-auto max-w-7xl")
        |> Map.put("children", [
          new_loop_node(
            if(template == "gallery",
              do: "grid gap-4 md:grid-cols-4",
              else: "grid gap-4 md:grid-cols-3"
            )
          )
        ])
      ])
    ]
  end

  defp template_tree(_template), do: []

  defp new_loop_node(classes) do
    %{
      "type" => "component",
      "name" => "loop",
      "id" => node_id("loop"),
      "props" => %{"source" => "collection_results", "as" => "item"},
      "classes" => %{"custom" => classes},
      "children" => [
        container_node("column", "card bg-base-100 p-5 shadow-sm")
        |> Map.put("children", [
          leaf_node(
            "image",
            %{"src" => "{{item.payload.image}}", "alt" => "{{item.title}}"},
            "aspect-video rounded-lg object-cover"
          ),
          leaf_node(
            "heading",
            %{"text" => "{{item.title}}", "level" => "3"},
            "mt-3 text-xl font-semibold"
          ),
          leaf_node(
            "paragraph",
            %{"text" => "{{item.payload.description}}"},
            "mt-2 text-base-content/70"
          ),
          leaf_node(
            "button",
            %{"text" => "Open", "href" => "/{{item.slug}}"},
            "btn btn-primary btn-sm mt-4"
          )
        ])
      ]
    }
  end

  defp container_node(name, classes) do
    %{
      "type" => "component",
      "name" => name,
      "id" => node_id(name),
      "props" => %{},
      "classes" => %{"custom" => classes},
      "children" => []
    }
  end

  defp leaf_node(name, props, classes) do
    %{
      "type" => "component",
      "name" => name,
      "id" => node_id(name),
      "props" => props,
      "classes" => %{"custom" => classes}
    }
  end

  defp node_id(prefix), do: "#{prefix}-#{Ecto.UUID.generate()}"

  defp merge_settings(defaults, params) do
    params = params || %{}

    defaults
    |> Map.merge(Map.drop(params, ["items_visible_desktop"]))
    |> put_in(
      ["items_visible", "desktop"],
      parse_integer(
        params["items_visible_desktop"],
        get_in(defaults, ["items_visible", "desktop"]) || 3
      )
    )
  end

  defp normalize_source_config(defaults, params) do
    defaults
    |> Map.merge(params || %{})
    |> maybe_drop_blank("collection_slug")
  end

  defp normalize_loop_settings(defaults, params) do
    defaults
    |> Map.merge(params || %{})
    |> Map.update("enabled", false, &parse_bool/1)
    |> Map.update("limit", 6, &parse_integer(&1, 6))
  end

  defp maybe_drop_blank(map, key) do
    if Map.get(map, key) in [nil, ""], do: Map.delete(map, key), else: map
  end

  defp collection_options(collections) do
    [{"Choose collection", ""}] ++ Enum.map(collections, &{&1.name, &1.slug})
  end

  defp setting_value(map, key, default), do: Map.get(map || %{}, key, default)

  defp bool_string(true), do: "true"
  defp bool_string("true"), do: "true"
  defp bool_string(_value), do: "false"

  defp parse_bool(value) when value in [true, "true", "1", 1], do: true
  defp parse_bool(_value), do: false

  defp parse_integer(value, _default) when is_integer(value), do: value

  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _other -> default
    end
  end

  defp parse_integer(_value, default), do: default
end
