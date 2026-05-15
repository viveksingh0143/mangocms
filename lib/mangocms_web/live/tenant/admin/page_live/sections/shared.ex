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
  attr :rest, :global

  def editable_text(%{multiline: true} = assigns) do
    assigns = assign_editable_values(assigns)

    ~H"""
    <textarea
      id={@id}
      name={@name}
      class="sr-only"
      tabindex="-1"
      aria-hidden="true"
      phx-debounce="500"
    >{@input_value}</textarea>
    <div
      id={"#{@id}_editable"}
      class={[
        "min-h-8 rounded-md transition focus-within:bg-base-200/60 focus-within:ring-2 focus-within:ring-primary/30",
        @class
      ]}
      {@rest}
    >
      <div
        id={"#{@id}_editable_input"}
        contenteditable="true"
        phx-hook="ContentEditableInput"
        phx-update="ignore"
        data-input-id={@id}
        data-multiline="true"
        data-placeholder={@placeholder || ""}
        data-placeholder-active={to_string(@placeholder_active)}
        role="textbox"
        aria-label={@label || @placeholder || @name}
        spellcheck="true"
        class="min-h-8 outline-none"
      >
        {@display_value}
      </div>
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
      phx-debounce="500"
    />
    <div
      id={"#{@id}_editable"}
      class={[
        "min-h-8 rounded-md transition focus-within:bg-base-200/60 focus-within:ring-2 focus-within:ring-primary/30",
        @class
      ]}
      {@rest}
    >
      <div
        id={"#{@id}_editable_input"}
        contenteditable="true"
        phx-hook="ContentEditableInput"
        phx-update="ignore"
        data-input-id={@id}
        data-multiline="false"
        data-placeholder={@placeholder || ""}
        data-placeholder-active={to_string(@placeholder_active)}
        role="textbox"
        aria-label={@label || @placeholder || @name}
        spellcheck="true"
        class="min-h-8 outline-none"
      >
        {@display_value}
      </div>
    </div>
    """
  end

  def fixed_value(form, key) do
    case form[:fixed_data].value do
      value when is_map(value) -> Map.get(value, key)
      _other -> nil
    end
  end

  def fixed_class_value(form, field) when is_binary(field) do
    fixed_value(form, "#{field}_classes")
  end

  def data_class_value(%PageSection{} = section, field) when is_binary(field) do
    data_value(section, "#{field}_classes")
  end

  def section_surface_class(%PageSection{} = section, base, fallback_background \\ "bg-base-100") do
    [
      base,
      settings_value(section, "background_class", fallback_background),
      settings_value(section, "border_class", "border-transparent"),
      settings_value(section, "extra_classes", nil)
    ]
  end

  def form_section_surface_class(
        %PageSection{} = section,
        form,
        base,
        fallback_background \\ "bg-base-100"
      ) do
    [
      base,
      form_settings_value(
        form,
        "background_class",
        settings_value(section, "background_class", fallback_background)
      ),
      form_settings_value(
        form,
        "border_class",
        settings_value(section, "border_class", "border-transparent")
      ),
      form_settings_value(form, "extra_classes", settings_value(section, "extra_classes", nil))
    ]
  end

  def hero_ratio_class(%PageSection{} = section) do
    ratio_class(settings_value(section, "content_ratio", "5:5"))
  end

  def form_hero_ratio_class(%PageSection{} = section, form) do
    form
    |> form_settings_value("content_ratio", settings_value(section, "content_ratio", "5:5"))
    |> ratio_class()
  end

  def form_settings_value(form, key, fallback \\ nil)

  def form_settings_value(form, key, fallback) do
    case form[:settings].value do
      value when is_map(value) -> non_empty_value(Map.get(value, key), fallback)
      _other -> fallback
    end
  end

  defp ratio_class(ratio) do
    case ratio do
      "2:8" -> "lg:grid-cols-[2fr_8fr]"
      "8:2" -> "lg:grid-cols-[8fr_2fr]"
      "6:4" -> "lg:grid-cols-[6fr_4fr]"
      "4:6" -> "lg:grid-cols-[4fr_6fr]"
      "7:3" -> "lg:grid-cols-[7fr_3fr]"
      "3:7" -> "lg:grid-cols-[3fr_7fr]"
      _ratio -> "lg:grid-cols-[5fr_5fr]"
    end
  end

  def settings_value(section, key, fallback \\ nil)

  def settings_value(%PageSection{settings: settings}, key, fallback) when is_map(settings) do
    non_empty_value(Map.get(settings, key), fallback)
  end

  def settings_value(_section, _key, fallback), do: fallback

  defp non_empty_value(value, fallback) when is_binary(value) do
    case String.trim(value) do
      "" -> fallback
      text -> text
    end
  end

  defp non_empty_value(value, _fallback) when not is_nil(value), do: value
  defp non_empty_value(_value, fallback), do: fallback

  def link_target(value) when value in ["_self", "_blank"], do: value
  def link_target(_value), do: "_self"

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
