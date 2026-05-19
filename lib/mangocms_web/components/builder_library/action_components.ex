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

  @doc "Renders an Alpine-powered dropdown."
  @spec dropdown(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :trigger
  slot :items

  def dropdown(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:trigger, fn -> [] end)
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <div
      class={["dropdown", dropdown_align(@props["align"]), class_value(@classes, "custom")]}
      x-data="{ open: false }"
      x-on:keydown.escape.window="open = false"
    >
      <button
        type="button"
        class={["btn", @props["button_style"] || "btn-ghost"]}
        x-on:click="open = !open"
        x-bind:aria-expanded="open.toString()"
      >
        <%= if @trigger != [] do %>
          {render_slot(@trigger)}
        <% else %>
          {@props["label"] || "Open menu"}
        <% end %>
      </button>
      <div
        class={[
          "dropdown-content z-20 mt-2 w-56 rounded-box bg-base-100 p-2 shadow",
          @props["menu_class"]
        ]}
        x-show="open"
        x-transition
        x-on:click.outside="open = false"
      >
        <%= if @items != [] do %>
          {render_slot(@items)}
        <% else %>
          <ul class="menu">
            <li :for={item <- menu_items(@props)}>
              <a href={item["href"] || "#"}>{item["label"]}</a>
            </li>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end

  @doc "Renders an Alpine-powered modal trigger and dialog."
  @spec modal(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :header
  slot :body
  slot :actions

  def modal(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:header, fn -> [] end)
      |> assign_new(:body, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)

    ~H"""
    <div x-data="{ open: false }" class={class_value(@classes, "custom")}>
      <button
        type="button"
        class={["btn", @props["trigger_style"] || "btn-primary"]}
        x-on:click="open = true"
      >
        {@props["trigger_label"] || "Open modal"}
      </button>
      <div
        class="modal"
        x-bind:class="{ 'modal-open': open }"
        x-on:keydown.escape.window="open = false"
      >
        <div class={["modal-box", modal_size(@props["size"])]}>
          <button
            type="button"
            class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
            x-on:click="open = false"
            aria-label="Close"
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
          <%= if @header != [] do %>
            {render_slot(@header)}
          <% else %>
            <h3 class="text-lg font-bold">{@props["title"] || "Modal title"}</h3>
          <% end %>
          <div class="py-4">
            <%= if @body != [] do %>
              {render_slot(@body)}
            <% else %>
              <p>{@props["body"] || "Modal content"}</p>
            <% end %>
          </div>
          <div class="modal-action">
            <%= if @actions != [] do %>
              {render_slot(@actions)}
            <% else %>
              <button type="button" class="btn" x-on:click="open = false">
                {@props["close_label"] || "Close"}
              </button>
            <% end %>
          </div>
        </div>
        <button
          type="button"
          class="modal-backdrop"
          x-on:click="open = false"
          aria-label="Close modal backdrop"
        >
        </button>
      </div>
    </div>
    """
  end

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""

  defp dropdown_align("end"), do: "dropdown-end"
  defp dropdown_align("top"), do: "dropdown-top"
  defp dropdown_align("left"), do: "dropdown-left"
  defp dropdown_align("right"), do: "dropdown-right"
  defp dropdown_align(_align), do: ""

  defp modal_size("sm"), do: "max-w-sm"
  defp modal_size("lg"), do: "max-w-3xl"
  defp modal_size("xl"), do: "max-w-5xl"
  defp modal_size(_size), do: ""

  defp menu_items(%{"items" => items}) when is_list(items), do: items

  defp menu_items(_props) do
    [
      %{"label" => "Profile", "href" => "#profile"},
      %{"label" => "Settings", "href" => "#settings"},
      %{"label" => "Logout", "href" => "#logout"}
    ]
  end
end
