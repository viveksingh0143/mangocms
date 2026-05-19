defmodule MangoCMSWeb.BuilderLibrary.NavigationComponents do
  @moduledoc """
  Pure Phoenix renderers for builder navigation components.
  """

  use MangoCMSWeb, :html

  @doc "Renders breadcrumb navigation."
  @spec breadcrumbs(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def breadcrumbs(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <nav class={["breadcrumbs text-sm", align_class(@props["align"]), class_value(@classes, "custom")]}>
      <ol>
        <%= if @items != [] do %>
          {render_slot(@items)}
        <% else %>
          <li :for={item <- nav_items(@props, "items", default_breadcrumbs())}>
            <a href={item["href"] || "#"}>{item["label"]}</a>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  @doc "Renders mobile dock navigation."
  @spec dock(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def dock(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <nav class={["dock", dock_position(@props["position"]), class_value(@classes, "custom")]}>
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <a
          :for={item <- nav_items(@props, "items", default_dock_items())}
          href={item["href"] || "#"}
          class={item_active?(item, @props["active_item"]) && "dock-active"}
        >
          <.icon name={item["icon"] || "hero-squares-2x2"} class="size-5" />
          <span class="dock-label">{item["label"]}</span>
        </a>
      <% end %>
    </nav>
    """
  end

  @doc "Renders a text or button-style navigation link."
  @spec nav_link(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def nav_link(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <a
      href={@props["href"] || "#"}
      target={@props["target"] || "_self"}
      class={[
        link_variant(@props["style"]),
        @props["active"] && active_link_class(@props["style"]),
        class_value(@classes, "custom")
      ]}
    >
      <.icon :if={@props["icon"] not in [nil, ""]} name={@props["icon"]} class="size-4" />
      {@props["label"] || "Link"}
    </a>
    """
  end

  @doc "Renders an Alpine-aware menu."
  @spec menu(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def menu(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <nav
      class={[
        "menu rounded-box",
        menu_direction(@props["direction"]),
        menu_size(@props["size"]),
        class_value(@classes, "custom")
      ]}
      x-data={"{ active: '#{@props["active_item"] || ""}' }"}
    >
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <li :for={item <- nav_items(@props, "items", default_menu_items())}>
          <a
            href={item["href"] || "#"}
            x-on:click={"active = '#{item["id"] || item["label"]}'"}
            x-bind:class={"active === '#{item["id"] || item["label"]}' && 'active'"}
          >
            <.icon :if={item["icon"] not in [nil, ""]} name={item["icon"]} class="size-4" />
            {item["label"]}
          </a>
        </li>
      <% end %>
    </nav>
    """
  end

  @doc "Renders an Alpine-powered responsive navbar."
  @spec navbar(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :brand
  slot :start
  slot :center
  slot :actions
  slot :mobile

  def navbar(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:brand, fn -> [] end)
      |> assign_new(:start, fn -> [] end)
      |> assign_new(:center, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)
      |> assign_new(:mobile, fn -> [] end)

    ~H"""
    <header
      class={[
        "navbar",
        navbar_tone(@props["tone"]),
        @props["sticky"] && "sticky top-0 z-30",
        class_value(@classes, "custom")
      ]}
      x-data="{ open: false }"
      x-on:keydown.escape.window="open = false"
    >
      <div class="navbar-start">
        <button
          type="button"
          class="btn btn-ghost lg:hidden"
          x-on:click="open = !open"
          aria-label="Toggle navigation"
        >
          <.icon name="hero-bars-3" class="size-5" />
        </button>
        <%= if @brand != [] do %>
          {render_slot(@brand)}
        <% else %>
          <a href={@props["brand_href"] || "/"} class="btn btn-ghost text-xl">
            {@props["brand_label"] || "MangoCMS"}
          </a>
        <% end %>
        <div :if={@start != []} class="hidden lg:flex">{render_slot(@start)}</div>
      </div>
      <div class={["navbar-center hidden lg:flex", align_class(@props["align"])]}>
        <%= if @center != [] do %>
          {render_slot(@center)}
        <% else %>
          <ul class="menu menu-horizontal px-1">
            <li :for={item <- nav_items(@props, "items", default_nav_items())}>
              <a
                href={item["href"] || "#"}
                class={item_active?(item, @props["active_item"]) && "active"}
              >
                {item["label"]}
              </a>
            </li>
          </ul>
        <% end %>
      </div>
      <div class="navbar-end">
        <%= if @actions != [] do %>
          {render_slot(@actions)}
        <% else %>
          <a
            href={@props["action_href"] || "#"}
            class={["btn", @props["action_style"] || "btn-primary"]}
          >
            {@props["action_label"] || "Get started"}
          </a>
        <% end %>
      </div>
      <div
        class="absolute inset-x-0 top-full z-20 border-t border-base-300 bg-base-100 p-3 shadow lg:hidden"
        x-show="open"
        x-transition
        x-on:click.outside="open = false"
      >
        <%= if @mobile != [] do %>
          {render_slot(@mobile)}
        <% else %>
          <ul class="menu">
            <li :for={item <- nav_items(@props, "items", default_nav_items())}>
              <a href={item["href"] || "#"}>{item["label"]}</a>
            </li>
          </ul>
        <% end %>
      </div>
    </header>
    """
  end

  @doc "Renders pagination controls."
  @spec pagination(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <nav class={["join", align_class(@props["align"]), class_value(@classes, "custom")]}>
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <a class="join-item btn" href={@props["previous_href"] || "#"}>Prev</a>
        <a
          :for={page <- page_items(@props)}
          class={["join-item btn", page == current_page(@props) && "btn-active"]}
          href={"#{@props["base_href"] || "#"}#{page}"}
        >
          {page}
        </a>
        <a class="join-item btn" href={@props["next_href"] || "#"}>Next</a>
      <% end %>
    </nav>
    """
  end

  @doc "Renders progress steps."
  @spec steps(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def steps(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <ul class={[
      "steps",
      steps_direction(@props["direction"]),
      steps_responsive(@props["responsive"]),
      class_value(@classes, "custom")
    ]}>
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <li
          :for={step <- step_items(@props)}
          class={["step", step.index <= active_step(@props) && "step-primary"]}
        >
          {step.label}
        </li>
      <% end %>
    </ul>
    """
  end

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""

  defp align_class("center"), do: "justify-center"
  defp align_class("end"), do: "justify-end"
  defp align_class(_align), do: "justify-start"

  defp dock_position("top"), do: "dock-top"
  defp dock_position(_position), do: "dock-bottom"

  defp link_variant("button"), do: "btn btn-primary"
  defp link_variant("ghost_button"), do: "btn btn-ghost"
  defp link_variant("menu_item"), do: "rounded-md px-3 py-2 hover:bg-base-200"
  defp link_variant(_style), do: "link link-hover"

  defp active_link_class("button"), do: "btn-active"
  defp active_link_class("ghost_button"), do: "btn-active"
  defp active_link_class("menu_item"), do: "bg-base-200 font-semibold"
  defp active_link_class(_style), do: "font-semibold text-primary"

  defp menu_direction("horizontal"), do: "menu-horizontal"
  defp menu_direction(_direction), do: ""

  defp menu_size("sm"), do: "menu-sm"
  defp menu_size("lg"), do: "menu-lg"
  defp menu_size(_size), do: ""

  defp navbar_tone("neutral"), do: "bg-neutral text-neutral-content"
  defp navbar_tone("base_200"), do: "bg-base-200 text-base-content"
  defp navbar_tone(_tone), do: "bg-base-100 text-base-content"

  defp steps_direction("vertical"), do: "steps-vertical"
  defp steps_direction(_direction), do: ""

  defp steps_responsive(true), do: "max-sm:steps-vertical"
  defp steps_responsive("true"), do: "max-sm:steps-vertical"
  defp steps_responsive(_responsive), do: ""

  defp nav_items(props, key, default) do
    case Map.get(props, key) do
      items when is_list(items) and items != [] -> items
      _other -> default
    end
  end

  defp item_active?(item, active_item), do: (item["id"] || item["label"]) == active_item

  defp page_items(props), do: 1..max(total_pages(props), 1)
  defp total_pages(props), do: parse_int(Map.get(props, "total_pages"), 5)
  defp current_page(props), do: parse_int(Map.get(props, "current_page"), 1)
  defp active_step(props), do: parse_int(Map.get(props, "active_step"), 2)

  defp parse_int(value, _default) when is_integer(value), do: value

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _rest} -> int
      :error -> default
    end
  end

  defp parse_int(_value, default), do: default

  defp step_items(props) do
    props
    |> nav_items("steps", [
      %{"label" => "Account"},
      %{"label" => "Profile"},
      %{"label" => "Publish"}
    ])
    |> Enum.with_index(1)
    |> Enum.map(fn {item, index} -> %{label: item["label"] || "Step #{index}", index: index} end)
  end

  defp default_breadcrumbs do
    [
      %{"label" => "Home", "href" => "/"},
      %{"label" => "CMS", "href" => "/admin"},
      %{"label" => "Pages", "href" => "#"}
    ]
  end

  defp default_dock_items do
    [
      %{"id" => "home", "label" => "Home", "href" => "/", "icon" => "hero-home"},
      %{
        "id" => "search",
        "label" => "Search",
        "href" => "#search",
        "icon" => "hero-magnifying-glass"
      },
      %{"id" => "account", "label" => "Account", "href" => "#account", "icon" => "hero-user"}
    ]
  end

  defp default_menu_items do
    [
      %{
        "id" => "dashboard",
        "label" => "Dashboard",
        "href" => "#dashboard",
        "icon" => "hero-squares-2x2"
      },
      %{
        "id" => "collections",
        "label" => "Collections",
        "href" => "#collections",
        "icon" => "hero-circle-stack"
      },
      %{
        "id" => "settings",
        "label" => "Settings",
        "href" => "#settings",
        "icon" => "hero-cog-6-tooth"
      }
    ]
  end

  defp default_nav_items do
    [
      %{"id" => "features", "label" => "Features", "href" => "#features"},
      %{"id" => "pricing", "label" => "Pricing", "href" => "#pricing"},
      %{"id" => "docs", "label" => "Docs", "href" => "#docs"}
    ]
  end
end
