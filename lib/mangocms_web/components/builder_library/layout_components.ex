defmodule MangoCMSWeb.BuilderLibrary.LayoutComponents do
  @moduledoc """
  Pure Phoenix renderers for builder layout components.
  """

  use MangoCMSWeb, :html

  @doc "Renders a divider between layout regions."
  @spec divider(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def divider(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "divider",
      divider_direction(@props["direction"]),
      divider_tone(@props["tone"]),
      divider_spacing(@props["spacing"]),
      class_value(@classes, "custom")
    ]}>
      <span :if={@props["label"] not in [nil, ""]}>{@props["label"]}</span>
    </div>
    """
  end

  @doc "Renders an Alpine-powered drawer/sidebar layout."
  @spec drawer(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :sidebar
  slot :content
  slot :actions

  def drawer(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:sidebar, fn -> [] end)
      |> assign_new(:content, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)

    ~H"""
    <section
      class={["drawer", drawer_side(@props["placement"]), class_value(@classes, "custom")]}
      x-data="{ open: false }"
      x-on:keydown.escape.window="open = false"
    >
      <input type="checkbox" class="drawer-toggle" x-bind:checked="open" />
      <div class="drawer-content">
        <div class="flex items-center justify-between gap-3 p-4">
          <button
            type="button"
            class={["btn", @props["trigger_style"] || "btn-primary"]}
            x-on:click="open = true"
          >
            <.icon name={@props["trigger_icon"] || "hero-bars-3"} class="size-4" />
            {@props["trigger_label"] || "Open sidebar"}
          </button>
          <div :if={@actions != []} class="flex flex-wrap gap-2">{render_slot(@actions)}</div>
        </div>
        <div class={["p-4", content_width(@props["content_width"])]}>
          <%= if @content != [] do %>
            {render_slot(@content)}
          <% else %>
            <div class="rounded-box border border-base-300 bg-base-100 p-6">
              <h3 class="text-lg font-semibold">{@props["title"] || "Drawer content"}</h3>
              <p class="mt-2 text-sm text-base-content/70">
                {@props["body"] || "Add components to the content slot."}
              </p>
            </div>
          <% end %>
        </div>
      </div>
      <aside class="drawer-side z-30">
        <button
          type="button"
          class="drawer-overlay"
          x-on:click="open = false"
          aria-label="Close sidebar"
        >
        </button>
        <div class={["min-h-full bg-base-200 p-4", drawer_width(@props["width"])]}>
          <div class="mb-4 flex items-center justify-between">
            <h3 class="font-semibold">{@props["sidebar_title"] || "Sidebar"}</h3>
            <button type="button" class="btn btn-ghost btn-sm btn-circle" x-on:click="open = false">
              <.icon name="hero-x-mark" class="size-4" />
            </button>
          </div>
          <%= if @sidebar != [] do %>
            {render_slot(@sidebar)}
          <% else %>
            <ul class="menu rounded-box bg-base-100">
              <li><a href="#overview">Overview</a></li>
              <li><a href="#settings">Settings</a></li>
              <li><a href="#support">Support</a></li>
            </ul>
          <% end %>
        </div>
      </aside>
    </section>
    """
  end

  @doc "Renders a footer layout."
  @spec footer(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :brand
  slot :links
  slot :social
  slot :legal

  def footer(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:brand, fn -> [] end)
      |> assign_new(:links, fn -> [] end)
      |> assign_new(:social, fn -> [] end)
      |> assign_new(:legal, fn -> [] end)

    ~H"""
    <footer class={[
      "footer",
      footer_layout(@props["layout"]),
      footer_tone(@props["tone"]),
      footer_padding(@props["padding"]),
      class_value(@classes, "custom")
    ]}>
      <aside>
        <%= if @brand != [] do %>
          {render_slot(@brand)}
        <% else %>
          <div class="grid gap-2">
            <div class="text-xl font-bold">{@props["brand"] || "MangoCMS"}</div>
            <p class="max-w-sm text-sm opacity-70">
              {@props["tagline"] || "Composable tenant websites with fast publishing."}
            </p>
          </div>
        <% end %>
      </aside>
      <nav>
        <h6 class="footer-title">{@props["links_title"] || "Links"}</h6>
        <%= if @links != [] do %>
          {render_slot(@links)}
        <% else %>
          <a :for={link <- footer_links(@props)} class="link link-hover" href={link["href"] || "#"}>
            {link["label"]}
          </a>
        <% end %>
      </nav>
      <nav :if={@social != []}>
        <h6 class="footer-title">Social</h6>
        {render_slot(@social)}
      </nav>
      <div :if={@legal != []} class="col-span-full">{render_slot(@legal)}</div>
    </footer>
    """
  end

  @doc "Renders a hero shell."
  @spec hero(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
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
    <section
      class={[
        "hero bg-base-200",
        hero_height(@props["height"]),
        class_value(@classes, "custom")
      ]}
      x-data="{ visible: true }"
    >
      <div class={[
        "hero-content w-full",
        content_width(@props["content_width"]),
        hero_layout(@props["layout"])
      ]}>
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

  @doc "Renders an indicator wrapper with badge position controls."
  @spec indicator(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :content
  slot :indicator

  def indicator(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:content, fn -> [] end)
      |> assign_new(:indicator, fn -> [] end)

    ~H"""
    <div class={["indicator", class_value(@classes, "custom")]}>
      <span class={[
        "indicator-item badge",
        indicator_position(@props["position"]),
        indicator_tone(@props["tone"])
      ]}>
        <%= if @indicator != [] do %>
          {render_slot(@indicator)}
        <% else %>
          {@props["label"] || "New"}
        <% end %>
      </span>
      <%= if @content != [] do %>
        {render_slot(@content)}
      <% else %>
        <div class="grid h-32 w-32 place-items-center rounded-box bg-base-200 text-sm">
          {@props["content_label"] || "Content"}
        </div>
      <% end %>
    </div>
    """
  end

  @doc "Renders a joined control group."
  @spec join(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def join(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <div class={[
      "join",
      join_direction(@props["direction"]),
      join_responsive(@props["responsive"]),
      class_value(@classes, "custom")
    ]}>
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <button :for={item <- join_items(@props)} type="button" class="btn join-item">
          {item["label"]}
        </button>
      <% end %>
    </div>
    """
  end

  @doc "Renders an image or slotted content with a mask shape."
  @spec mask(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :content

  def mask(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:content, fn -> [] end)

    ~H"""
    <div class={[
      "mask overflow-hidden",
      mask_shape(@props["shape"]),
      mask_size(@props["size"]),
      class_value(@classes, "custom")
    ]}>
      <%= if @content != [] do %>
        {render_slot(@content)}
      <% else %>
        <img
          src={@props["image_src"] || "/images/no-image-placeholder.webp"}
          alt={@props["image_alt"] || ""}
          class="h-full w-full object-cover"
        />
      <% end %>
    </div>
    """
  end

  @doc "Renders a stacked card/image composition."
  @spec stack(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def stack(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <div class={["stack", stack_size(@props["size"]), class_value(@classes, "custom")]}>
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <div
          :for={item <- stack_items(@props)}
          class={[
            "grid place-items-center rounded-box border border-base-300 bg-base-100",
            item.class
          ]}
        >
          <span class="font-semibold">{item.label}</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp hero_layout("split_right"), do: "flex-col lg:flex-row-reverse"
  defp hero_layout("centered"), do: "text-center"
  defp hero_layout(_layout), do: "flex-col lg:flex-row"

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""

  defp divider_direction("horizontal"), do: "divider-horizontal"
  defp divider_direction(_direction), do: ""

  defp divider_tone("primary"), do: "text-primary"
  defp divider_tone("secondary"), do: "text-secondary"
  defp divider_tone("accent"), do: "text-accent"
  defp divider_tone(_tone), do: ""

  defp divider_spacing("compact"), do: "my-2"
  defp divider_spacing("relaxed"), do: "my-10"
  defp divider_spacing(_spacing), do: "my-6"

  defp drawer_side("right"), do: "drawer-end"
  defp drawer_side(_placement), do: ""

  defp drawer_width("sm"), do: "w-64"
  defp drawer_width("lg"), do: "w-96"
  defp drawer_width("xl"), do: "w-[32rem]"
  defp drawer_width(_width), do: "w-80"

  defp content_width("narrow"), do: "max-w-3xl"
  defp content_width("wide"), do: "max-w-7xl"
  defp content_width("full"), do: "max-w-none"
  defp content_width(_width), do: "max-w-5xl"

  defp footer_layout("centered"), do: "footer-center"
  defp footer_layout(_layout), do: ""

  defp footer_tone("neutral"), do: "bg-neutral text-neutral-content"
  defp footer_tone("base_200"), do: "bg-base-200 text-base-content"
  defp footer_tone(_tone), do: "bg-base-100 text-base-content"

  defp footer_padding("compact"), do: "p-6"
  defp footer_padding("relaxed"), do: "p-12"
  defp footer_padding(_padding), do: "p-10"

  defp footer_links(%{"links" => links}) when is_list(links), do: links

  defp footer_links(_props) do
    [
      %{"label" => "Pages", "href" => "#pages"},
      %{"label" => "Collections", "href" => "#collections"},
      %{"label" => "Contact", "href" => "#contact"}
    ]
  end

  defp hero_height("compact"), do: "min-h-80"
  defp hero_height("full"), do: "min-h-screen"
  defp hero_height(_height), do: "min-h-[28rem]"

  defp indicator_position("top_start"), do: "indicator-start indicator-top"
  defp indicator_position("bottom_end"), do: "indicator-end indicator-bottom"
  defp indicator_position("bottom_start"), do: "indicator-start indicator-bottom"
  defp indicator_position(_position), do: "indicator-end indicator-top"

  defp indicator_tone("primary"), do: "badge-primary"
  defp indicator_tone("secondary"), do: "badge-secondary"
  defp indicator_tone("accent"), do: "badge-accent"
  defp indicator_tone("success"), do: "badge-success"
  defp indicator_tone(_tone), do: "badge-primary"

  defp join_direction("vertical"), do: "join-vertical"
  defp join_direction(_direction), do: "join-horizontal"

  defp join_responsive(true), do: "max-sm:join-vertical"
  defp join_responsive("true"), do: "max-sm:join-vertical"
  defp join_responsive(_responsive), do: ""

  defp join_items(%{"items" => items}) when is_list(items), do: items

  defp join_items(_props) do
    [
      %{"label" => "One"},
      %{"label" => "Two"},
      %{"label" => "Three"}
    ]
  end

  defp mask_shape("squircle"), do: "mask-squircle"
  defp mask_shape("heart"), do: "mask-heart"
  defp mask_shape("hexagon"), do: "mask-hexagon"
  defp mask_shape("triangle"), do: "mask-triangle"
  defp mask_shape(_shape), do: "mask-circle"

  defp mask_size("sm"), do: "size-24"
  defp mask_size("lg"), do: "size-48"
  defp mask_size("xl"), do: "size-64"
  defp mask_size(_size), do: "size-36"

  defp stack_size("sm"), do: "w-32"
  defp stack_size("lg"), do: "w-72"
  defp stack_size(_size), do: "w-56"

  defp stack_items(%{"items" => items}) when is_list(items) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      %{label: item["label"] || "Layer #{index + 1}", class: item["class"] || "aspect-[4/3]"}
    end)
  end

  defp stack_items(_props) do
    [
      %{label: "Front", class: "aspect-[4/3]"},
      %{label: "Middle", class: "aspect-[4/3]"},
      %{label: "Back", class: "aspect-[4/3]"}
    ]
  end
end
