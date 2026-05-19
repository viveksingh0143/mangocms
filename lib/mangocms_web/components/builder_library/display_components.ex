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
      |> assign_new(:media, fn -> [] end)
      |> assign_new(:body, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)

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

  @doc "Renders a carousel with Alpine local controls."
  @spec carousel(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def carousel(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <div
      class={["relative", class_value(@classes, "custom")]}
      x-data={"{ active: 0, total: #{@props["items_count"] || 3} }"}
    >
      <div class={["carousel w-full", carousel_mode(@props["transition"])]}>
        <%= if @items != [] do %>
          {render_slot(@items)}
        <% else %>
          <div
            :for={item <- carousel_items(@props)}
            class="carousel-item w-full"
            x-show={"active === #{item.index}"}
            x-transition
          >
            <div class="hero min-h-64 rounded-box bg-base-200">
              <div class="hero-content text-center">
                <div>
                  <h3 class="text-2xl font-bold">{item.title}</h3>
                  <p class="py-3">{item.body}</p>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
      <div
        :if={@props["controls_enabled"] != false}
        class="absolute inset-x-4 top-1/2 flex -translate-y-1/2 justify-between"
      >
        <button
          type="button"
          class="btn btn-circle"
          x-on:click="active = (active - 1 + total) % total"
        >
          Prev
        </button>
        <button type="button" class="btn btn-circle" x-on:click="active = (active + 1) % total">
          Next
        </button>
      </div>
    </div>
    """
  end

  @doc "Renders Alpine-powered tabs."
  @spec tabs(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :panels

  def tabs(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:panels, fn -> [] end)

    ~H"""
    <div
      class={class_value(@classes, "custom")}
      x-data="{ active: 0 }"
    >
      <div role="tablist" class={["tabs", @props["style"] || "tabs-boxed"]}>
        <button
          :for={tab <- tab_items(@props)}
          type="button"
          role="tab"
          class="tab"
          x-bind:class={"active === #{tab.index} && 'tab-active'"}
          x-on:click={"active = #{tab.index}"}
        >
          {tab.label}
        </button>
      </div>
      <div class="mt-4">
        <%= if @panels != [] do %>
          {render_slot(@panels)}
        <% else %>
          <section
            :for={tab <- tab_items(@props)}
            x-show={"active === #{tab.index}"}
            x-transition
            class="rounded-box border border-base-300 p-4"
          >
            <h3 class="font-semibold">{tab.label}</h3>
            <p class="mt-2 text-sm text-base-content/70">{tab.body}</p>
          </section>
        <% end %>
      </div>
    </div>
    """
  end

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""

  defp carousel_mode("fade"), do: "overflow-hidden"
  defp carousel_mode(_transition), do: "carousel-center"

  defp carousel_items(props) do
    props
    |> Map.get("items", [
      %{"title" => "First slide", "body" => "Introduce your story."},
      %{"title" => "Second slide", "body" => "Show a useful detail."},
      %{"title" => "Third slide", "body" => "Close with a clear action."}
    ])
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      %{index: index, title: item["title"] || "Slide", body: item["body"] || ""}
    end)
  end

  defp tab_items(props) do
    props
    |> Map.get("tabs", [
      %{"label" => "Overview", "body" => "Overview content"},
      %{"label" => "Details", "body" => "Details content"},
      %{"label" => "Settings", "body" => "Settings content"}
    ])
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      %{index: index, label: item["label"] || "Tab", body: item["body"] || ""}
    end)
  end
end
