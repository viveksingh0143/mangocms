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

  def fixed_value(form, key) do
    case form[:fixed_data].value do
      value when is_map(value) -> Map.get(value, key)
      _other -> nil
    end
  end

  def settings_value(form, key, fallback) do
    case form[:settings].value do
      value when is_map(value) ->
        case Map.get(value, key) do
          setting when is_binary(setting) and setting != "" -> setting
          _other -> fallback
        end

      _other ->
        fallback
    end
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
