defmodule MangoCMSWeb.BuilderLibrary.ActionComponents do
  @moduledoc """
  Pure Phoenix renderers for builder action components.

  These components do not know about the builder inspector or editor chrome.
  """

  use MangoCMSWeb, :html

  @doc "Renders a button/link using node props and classes."
  @spec button(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true

  def button(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <a
      href={@props["href"] || "#"}
      target={@props["target"] || "_self"}
      class={["btn", @props["style"] || "btn-primary", class_value(@classes, "custom")]}
    >
      <.icon :if={@props["icon"] not in [nil, ""]} name={@props["icon"]} class="size-4" />
      {@props["label"] || "Button"}
    </a>
    """
  end

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""
end
