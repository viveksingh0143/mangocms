defmodule MangoCMSWeb.BuilderLibrary.InputComponents do
  @moduledoc """
  Pure Phoenix renderers for builder input components.
  """

  use MangoCMSWeb, :html

  @doc "Renders a standalone input field preview."
  @spec input(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def input(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <label class={["form-control w-full", class_value(@classes, "custom")]}>
      <div :if={@props["label"] not in [nil, ""]} class="label">
        <span class="label-text">{@props["label"]}</span>
      </div>
      <input
        type={@props["input_type"] || "text"}
        name={@props["field_name"] || "field"}
        placeholder={@props["placeholder"] || ""}
        value={@props["value"] || ""}
        required={@props["required"] == true}
        disabled={@props["disabled"] == true}
        class={["input w-full", @props["style"] || "input-bordered"]}
      />
      <div :if={@props["help"] not in [nil, ""]} class="label">
        <span class="label-text-alt">{@props["help"]}</span>
      </div>
    </label>
    """
  end

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""
end
