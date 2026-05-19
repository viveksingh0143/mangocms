defmodule MangoCMSWeb.BuilderLibrary.DisplayComponents do
  @moduledoc """
  Pure Phoenix renderers for builder display components.
  """

  use MangoCMSWeb, :html

  @doc "Renders a card component shell."
  @spec card(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  slot :media
  slot :body
  slot :actions

  def card(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <article class={[
      "card bg-base-100",
      @props["style"] || "shadow-sm",
      class_value(@classes, "custom")
    ]}>
      <figure :if={@props["image_enabled"] && @props["image_position"] == "top"}>
        <img src={@props["image_src"] || "/images/placeholder.svg"} alt={@props["image_alt"] || ""} />
      </figure>
      {render_slot(@media)}
      <div class="card-body">
        <h3 class="card-title">{@props["title"] || "Card title"}</h3>
        <p>{@props["body"] || "Card body"}</p>
        {render_slot(@body)}
        <div :if={@actions != []} class="card-actions justify-end">{render_slot(@actions)}</div>
      </div>
      <figure :if={@props["image_enabled"] && @props["image_position"] == "bottom"}>
        <img src={@props["image_src"] || "/images/placeholder.svg"} alt={@props["image_alt"] || ""} />
      </figure>
    </article>
    """
  end

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""
end
