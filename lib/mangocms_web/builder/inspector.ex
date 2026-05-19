defmodule MangoCMSWeb.Builder.Inspector do
  @moduledoc """
  Generic manifest-driven inspector controls for builder sidebars.

  The inspector only renders editable controls from a manifest. It does not
  mutate the content tree directly; parent LiveViews decide how submitted
  params are applied.
  """

  use MangoCMSWeb, :html

  alias MangoCMSWeb.Builder.Registry

  attr :manifest, :map, required: true
  attr :node, :map, default: %{}
  attr :variant_id, :string, default: nil
  attr :form_name, :string, default: "node"
  attr :id_prefix, :string, default: "builder-manifest-inspector"

  @doc "Renders right-sidebar controls for the selected manifest variant."
  @spec fields(map()) :: Phoenix.LiveView.Rendered.t()
  def fields(assigns) do
    variant_id = assigns.variant_id || get_in(assigns.node, ["variant"])
    fields = Registry.fields_for_variant(assigns.manifest, variant_id)
    slots = Registry.slots_for_variant(assigns.manifest, variant_id)

    assigns =
      assigns
      |> assign(:fields, fields)
      |> assign(:slots, slots)

    ~H"""
    <div id={@id_prefix} class="grid gap-4">
      <div>
        <p class="text-xs font-semibold uppercase tracking-wide text-base-content/50">
          {@manifest.group}
        </p>
        <h3 class="text-base font-semibold text-base-content">{@manifest.label}</h3>
      </div>

      <.field_control
        :for={field <- @fields}
        field={field}
        value={field_value(@node, field)}
        slots={@slots}
        form_name={@form_name}
        id_prefix={@id_prefix}
      />
    </div>
    """
  end

  attr :field, :map, required: true
  attr :value, :any, default: nil
  attr :slots, :list, default: []
  attr :form_name, :string, required: true
  attr :id_prefix, :string, required: true

  defp field_control(assigns) do
    assigns =
      assigns
      |> assign(:input_id, input_id(assigns.id_prefix, assigns.field))
      |> assign(:input_name, input_name(assigns.form_name, assigns.field))

    ~H"""
    <div>
      <%= case @field.type do %>
        <% :textarea -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="textarea"
            label={@field.label}
            value={@value || ""}
            placeholder={@field[:placeholder]}
            required={@field.required}
          />
        <% :select -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="select"
            label={@field.label}
            value={@value || ""}
            options={@field[:options] || []}
            required={@field.required}
          />
        <% :toggle -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="checkbox"
            label={@field.label}
            value={@value}
            checked={truthy?(@value)}
          />
        <% :number -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="number"
            label={@field.label}
            value={@value || ""}
            min={@field[:min]}
            max={@field[:max]}
            step={@field[:step]}
            required={@field.required}
          />
        <% :color -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="color"
            label={@field.label}
            value={@value || "#000000"}
            required={@field.required}
          />
        <% :link -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="url"
            label={@field.label}
            value={@value || ""}
            placeholder={@field[:placeholder] || "https://example.com or /path"}
            required={@field.required}
          />
        <% :media -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="text"
            label={@field.label}
            value={@value || ""}
            placeholder={@field[:placeholder] || "Select or upload media"}
            required={@field.required}
          />
        <% :icon -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="text"
            label={@field.label}
            value={@value || ""}
            placeholder={@field[:placeholder] || "hero-sparkles"}
            required={@field.required}
          />
        <% :action_list -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="textarea"
            label={@field.label}
            value={inspect(@value || [])}
            placeholder="Action list"
          />
        <% :class_list -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="textarea"
            label={@field.label}
            value={@value || ""}
            placeholder={@field[:placeholder] || "Add Tailwind/daisyUI classes"}
          />
        <% :slot_controls -> %>
          <div id={@input_id} class="rounded-lg border border-base-300 p-3">
            <p class="text-sm font-medium">{@field.label}</p>
            <div class="mt-3 grid gap-2">
              <div :for={slot <- @slots} class="rounded-md bg-base-200 p-2 text-sm">
                <div class="flex items-center justify-between gap-2">
                  <span class="font-medium">{slot.label}</span>
                  <span class="text-xs text-base-content/60">{Enum.join(slot.accepts, ", ")}</span>
                </div>
              </div>
            </div>
          </div>
        <% _other -> %>
          <.input
            id={@input_id}
            name={@input_name}
            type="text"
            label={@field.label}
            value={@value || ""}
            placeholder={@field[:placeholder]}
            required={@field.required}
          />
      <% end %>

      <p :if={@field[:help]} class="mt-1 text-xs text-base-content/60">{@field[:help]}</p>
      <p :if={@field.bindable} class="mt-1 text-xs text-primary">Supports dynamic bindings.</p>
    </div>
    """
  end

  defp field_value(node, %{scope: :props, key: key}), do: get_in(node, ["props", key])
  defp field_value(node, %{scope: :classes, key: key}), do: get_in(node, ["classes", key])
  defp field_value(node, %{scope: :settings, key: key}), do: get_in(node, ["settings", key])
  defp field_value(node, %{scope: :slots, key: key}), do: get_in(node, ["slots", key])
  defp field_value(_node, _field), do: nil

  defp input_name(form_name, field), do: "#{form_name}[#{field.scope}][#{field.key}]"
  defp input_id(prefix, field), do: "#{prefix}-#{field.scope}-#{field.key}"

  defp truthy?(value), do: value in [true, "true", "1", 1]
end
