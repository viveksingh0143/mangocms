defmodule MangoCMSWeb.Tenant.Admin.PageLive.Sections.Shared do
  @moduledoc false

  use MangoCMSWeb, :html

  alias MangoCMS.Tenant.Pages.PageSection

  attr :section, PageSection, required: true
  attr :type, :string, required: true
  attr :template_id, :string, required: true
  attr :mode, :string, required: true

  def hidden_section_fields(assigns) do
    ~H"""
    <.input
      type="hidden"
      id={"builder_section_#{@section.id}_type"}
      name="section[type]"
      value={@type}
    />
    <.input
      type="hidden"
      id={"builder_section_#{@section.id}_template_id"}
      name="section[template_id]"
      value={@template_id}
    />
    <.input
      type="hidden"
      id={"builder_section_#{@section.id}_mode"}
      name="section[mode]"
      value={@mode}
    />
    <.input
      type="hidden"
      id={"builder_section_#{@section.id}_position"}
      name="section[position]"
      value={@section.position || 0}
    />
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :class, :any, default: nil
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :multiline, :boolean, default: false

  def editable_text(%{multiline: true} = assigns) do
    assigns = assign_editable_values(assigns)

    ~H"""
    <textarea id={@id} name={@name} class="sr-only" tabindex="-1" aria-hidden="true">{@input_value}</textarea>
    <div
      id={"#{@id}_editable"}
      contenteditable="true"
      phx-hook="ContentEditableInput"
      data-input-id={@id}
      data-multiline="true"
      data-placeholder={@placeholder || ""}
      data-placeholder-active={to_string(@placeholder_active)}
      role="textbox"
      aria-label={@label || @placeholder || @name}
      spellcheck="true"
      class={[
        "min-h-8 rounded-md outline-none transition focus:bg-base-200/60 focus:ring-2 focus:ring-primary/30",
        @class
      ]}
    >
      {@display_value}
    </div>
    """
  end

  def editable_text(assigns) do
    assigns = assign_editable_values(assigns)

    ~H"""
    <input
      id={@id}
      name={@name}
      type="text"
      value={@input_value}
      class="sr-only"
      tabindex="-1"
      aria-hidden="true"
    />
    <div
      id={"#{@id}_editable"}
      contenteditable="true"
      phx-hook="ContentEditableInput"
      data-input-id={@id}
      data-multiline="false"
      data-placeholder={@placeholder || ""}
      data-placeholder-active={to_string(@placeholder_active)}
      role="textbox"
      aria-label={@label || @placeholder || @name}
      spellcheck="true"
      class={[
        "min-h-8 rounded-md outline-none transition focus:bg-base-200/60 focus:ring-2 focus:ring-primary/30",
        @class
      ]}
    >
      {@display_value}
    </div>
    """
  end

  def fixed_value(form, key) do
    case form[:fixed_data].value do
      value when is_map(value) -> Map.get(value, key)
      _other -> nil
    end
  end

  defp assign_editable_values(assigns) do
    input_value =
      cond do
        is_binary(assigns.value) -> assigns.value
        not is_nil(assigns.value) -> to_string(assigns.value)
        true -> ""
      end

    placeholder_active = String.trim(input_value) == "" and is_binary(assigns.placeholder)
    display_value = if placeholder_active, do: assigns.placeholder, else: input_value

    assigns
    |> assign(:input_value, input_value)
    |> assign(:display_value, display_value)
    |> assign(:placeholder_active, placeholder_active)
  end

  def data_value(%PageSection{fixed_data: fixed_data}, key) when is_map(fixed_data) do
    case Map.get(fixed_data, key) do
      value when is_binary(value) and value != "" -> value
      value when not is_nil(value) -> to_string(value)
      _other -> nil
    end
  end

  def data_value(_section, _key), do: nil

  def text_or(value, fallback) when is_binary(value) do
    case String.trim(value) do
      "" -> fallback
      text -> text
    end
  end

  def text_or(_value, fallback), do: fallback

  def source_value(params, key), do: Map.get(params, key)
  def source_filter_value(params, key), do: get_in(params, ["filters", key])
  def source_sort_value(params, key), do: get_in(params, ["sort", key])

  def mapping_label(slot) when is_binary(slot) do
    slot
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def human_label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def human_label(_value), do: "Unknown"
end
