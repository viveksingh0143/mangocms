defmodule MangoCMSWeb.BuilderLibrary.LayoutComponents do
  @moduledoc """
  Pure Phoenix renderers for builder layout components.
  """

  use MangoCMSWeb, :html

  @doc "Renders a hero shell."
  @spec hero(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  slot :content
  slot :media
  slot :actions

  def hero(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:content, fn -> [] end)
      |> assign_new(:media, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)

    ~H"""
    <section class={["hero min-h-[28rem] bg-base-200", class_value(@classes, "custom")]}>
      <div class={["hero-content w-full max-w-7xl", hero_layout(@props["layout"])]}>
        <div class="max-w-xl">
          <p :if={@props["eyebrow"] not in [nil, ""]} class="text-sm font-semibold text-primary">
            {@props["eyebrow"]}
          </p>
          <h1 class="text-5xl font-bold">{@props["title"] || "Hero title"}</h1>
          <p class="py-6">{@props["subtitle"] || "Hero subtitle"}</p>
          {render_slot(@content)}
          <div :if={@actions != []} class="flex flex-wrap gap-3">{render_slot(@actions)}</div>
        </div>
        <div :if={@media != []}>{render_slot(@media)}</div>
      </div>
    </section>
    """
  end

  defp hero_layout("split_right"), do: "flex-col lg:flex-row-reverse"
  defp hero_layout("centered"), do: "text-center"
  defp hero_layout(_layout), do: "flex-col lg:flex-row"

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""
end
