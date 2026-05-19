defmodule MangoCMSWeb.BuilderLibrary.DisplayComponents do
  @moduledoc """
  Pure Phoenix renderers for builder display components.
  """

  use MangoCMSWeb, :html

  @doc "Renders an Alpine-powered accordion."
  @spec accordion(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def accordion(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <div
      class={[
        "join join-vertical w-full",
        accordion_spacing(@props["spacing"]),
        class_value(@classes, "custom")
      ]}
      x-data={"{ open: '#{@props["default_open"] || first_item_id(@props, "accordion_1")}' }"}
    >
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <section
          :for={item <- accordion_items(@props)}
          class={["collapse join-item border border-base-300", accordion_style(@props["style"])]}
          x-bind:class={"open === '#{item.id}' && 'collapse-open'"}
        >
          <button
            type="button"
            class="collapse-title text-left text-base font-medium"
            x-on:click={"open = open === '#{item.id}' ? '' : '#{item.id}'"}
          >
            {item.title}
          </button>
          <div class="collapse-content">
            <p class="text-sm text-base-content/70">{item.body}</p>
          </div>
        </section>
      <% end %>
    </div>
    """
  end

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
        <p
          :if={@props["eyebrow"] not in [nil, ""]}
          class="text-xs font-semibold uppercase text-primary"
        >
          {@props["eyebrow"]}
        </p>
        <p>{@props["body"] || "Card body"}</p>
        <div :if={@props["meta"] not in [nil, ""]} class="text-sm text-base-content/60">
          {@props["meta"]}
        </div>
        {render_slot(@body)}
        <div :if={@actions != []} class="card-actions justify-end">{render_slot(@actions)}</div>
      </div>
      <figure :if={@props["image_enabled"] && @props["image_position"] == "bottom"}>
        <img src={@props["image_src"] || "/images/placeholder.svg"} alt={@props["image_alt"] || ""} />
      </figure>
    </article>
    """
  end

  @doc "Renders an Alpine-powered collapse panel."
  @spec collapse(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :title
  slot :content

  def collapse(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:title, fn -> [] end)
      |> assign_new(:content, fn -> [] end)

    ~H"""
    <section
      class={[
        "collapse border border-base-300 bg-base-100",
        collapse_style(@props["style"]),
        class_value(@classes, "custom")
      ]}
      x-data={"{ open: #{@props["default_open"] == true} }"}
      x-bind:class="{ 'collapse-open': open, 'collapse-close': !open }"
    >
      <button
        type="button"
        class="collapse-title text-left text-lg font-medium"
        x-on:click="open = !open"
      >
        <%= if @title != [] do %>
          {render_slot(@title)}
        <% else %>
          {@props["title"] || "Collapse title"}
        <% end %>
      </button>
      <div class="collapse-content">
        <%= if @content != [] do %>
          {render_slot(@content)}
        <% else %>
          <p class="text-sm text-base-content/70">{@props["body"] || "Collapse content"}</p>
        <% end %>
      </div>
    </section>
    """
  end

  @doc "Renders a collection-friendly list."
  @spec list(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def list(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <div class={[
      "list rounded-box bg-base-100 shadow-sm",
      list_density(@props["density"]),
      class_value(@classes, "custom")
    ]}>
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <div :for={item <- display_items(@props, default_list_items())} class="list-row">
          <div>
            <div class="font-medium">
              {item["title"] || @props["title_template"] || "{{item.title}}"}
            </div>
            <div class="text-xs uppercase font-semibold opacity-60">
              {item["meta"] || @props["meta_template"] || "{{item.category}}"}
            </div>
          </div>
          <p class="list-col-wrap text-sm text-base-content/70">
            {item["body"] || @props["body_template"] || "{{item.excerpt}}"}
          </p>
          <a href={item["href"] || "#"} class="btn btn-square btn-ghost">
            <.icon name="hero-arrow-right" class="size-4" />
          </a>
        </div>
      <% end %>
    </div>
    """
  end

  @doc "Renders a stat block."
  @spec stat(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :figure
  slot :actions

  def stat(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:figure, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)

    ~H"""
    <section class={[
      "stats bg-base-100",
      @props["style"] || "shadow-sm",
      stat_orientation(@props["orientation"]),
      class_value(@classes, "custom")
    ]}>
      <div class="stat">
        <div :if={@figure != [] || @props["icon"] not in [nil, ""]} class="stat-figure text-primary">
          <%= if @figure != [] do %>
            {render_slot(@figure)}
          <% else %>
            <.icon name={@props["icon"]} class="size-8" />
          <% end %>
        </div>
        <div class="stat-title">{@props["label"] || "{{item.label}}"}</div>
        <div class="stat-value">{@props["value"] || "{{item.value}}"}</div>
        <div class="stat-desc">{@props["description"] || "{{item.description}}"}</div>
        <div :if={@actions != []} class="stat-actions mt-3">{render_slot(@actions)}</div>
      </div>
    </section>
    """
  end

  @doc "Renders a collection-friendly table."
  @spec table(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :header
  slot :rows

  def table(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:header, fn -> [] end)
      |> assign_new(:rows, fn -> [] end)

    ~H"""
    <div class={["overflow-x-auto", class_value(@classes, "custom")]}>
      <table class={["table", table_size(@props["size"]), @props["zebra"] && "table-zebra"]}>
        <thead>
          <%= if @header != [] do %>
            {render_slot(@header)}
          <% else %>
            <tr>
              <th :for={column <- table_columns(@props)}>{column["label"]}</th>
            </tr>
          <% end %>
        </thead>
        <tbody>
          <%= if @rows != [] do %>
            {render_slot(@rows)}
          <% else %>
            <tr :for={item <- display_items(@props, default_table_items())}>
              <td :for={column <- table_columns(@props)}>
                {table_cell(item, column)}
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @doc "Renders a timeline."
  @spec timeline(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def timeline(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <ul class={[
      "timeline",
      timeline_direction(@props["direction"]),
      timeline_compact(@props["compact"]),
      class_value(@classes, "custom")
    ]}>
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <li :for={item <- timeline_items(@props)}>
          <hr />
          <div class="timeline-start text-sm opacity-70">{item.date}</div>
          <div class="timeline-middle">
            <.icon name={@props["icon"] || "hero-check-circle"} class="size-5 text-primary" />
          </div>
          <div class="timeline-end timeline-box">
            <div class="font-semibold">{item.title}</div>
            <p class="text-sm text-base-content/70">{item.body}</p>
          </div>
          <hr />
        </li>
      <% end %>
    </ul>
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
      x-data={"{ active: '#{active_tab(@props)}' }"}
    >
      <div
        role="tablist"
        class={[
          "tabs",
          @props["style"] || "tabs-boxed",
          tabs_align(@props["align"]),
          tabs_responsive(@props["responsive"])
        ]}
      >
        <button
          :for={tab <- tab_items(@props)}
          type="button"
          role="tab"
          class="tab"
          x-bind:class={"active === '#{tab.id}' && 'tab-active'"}
          x-on:click={"active = '#{tab.id}'"}
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
            x-show={"active === '#{tab.id}'"}
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

  defp accordion_style("arrow"), do: "collapse-arrow"
  defp accordion_style("plus"), do: "collapse-plus"
  defp accordion_style(_style), do: ""

  defp accordion_spacing("separated"), do: "gap-2"
  defp accordion_spacing(_spacing), do: ""

  defp collapse_style("arrow"), do: "collapse-arrow"
  defp collapse_style("plus"), do: "collapse-plus"
  defp collapse_style(_style), do: ""

  defp list_density("compact"), do: "text-sm"
  defp list_density("relaxed"), do: "gap-2"
  defp list_density(_density), do: ""

  defp stat_orientation("vertical"), do: "stats-vertical"
  defp stat_orientation(_orientation), do: ""

  defp table_size("xs"), do: "table-xs"
  defp table_size("sm"), do: "table-sm"
  defp table_size("lg"), do: "table-lg"
  defp table_size(_size), do: ""

  defp timeline_direction("vertical"), do: "timeline-vertical"
  defp timeline_direction(_direction), do: "timeline-horizontal"

  defp timeline_compact(true), do: "timeline-compact"
  defp timeline_compact("true"), do: "timeline-compact"
  defp timeline_compact(_compact), do: ""

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

  defp accordion_items(props) do
    props
    |> display_items([
      %{
        "id" => "accordion_1",
        "title" => "What can I publish?",
        "body" => "Pages, catalogs, reviews, and custom collections."
      },
      %{
        "id" => "accordion_2",
        "title" => "Can this bind to collections?",
        "body" => "Yes, use {{item.field}} placeholders in titles and bodies."
      }
    ])
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      %{
        id: item["id"] || "accordion_#{index + 1}",
        title: item["title"] || props["title_template"] || "{{item.title}}",
        body: item["body"] || props["body_template"] || "{{item.body}}"
      }
    end)
  end

  defp first_item_id(props, fallback) do
    props
    |> accordion_items()
    |> List.first(%{id: fallback})
    |> Map.get(:id, fallback)
  end

  defp display_items(props, default) do
    case Map.get(props, "items") do
      items when is_list(items) and items != [] -> items
      _other -> default
    end
  end

  defp table_columns(props) do
    case Map.get(props, "columns") do
      columns when is_list(columns) and columns != [] ->
        columns

      _other ->
        [
          %{"label" => "Name", "field" => "title"},
          %{"label" => "Status", "field" => "status"},
          %{"label" => "Updated", "field" => "updated_at"}
        ]
    end
  end

  defp table_cell(item, column) do
    field = column["field"] || "field"
    Map.get(item, field, "{{item.#{field}}}")
  end

  defp timeline_items(props) do
    props
    |> display_items([
      %{"date" => "2026", "title" => "Tenant launched", "body" => "Website content went live."},
      %{"date" => "2027", "title" => "Catalog added", "body" => "Products and reviews connected."}
    ])
    |> Enum.map(fn item ->
      %{
        date: item["date"] || props["date_template"] || "{{item.date}}",
        title: item["title"] || props["title_template"] || "{{item.title}}",
        body: item["body"] || props["body_template"] || "{{item.body}}"
      }
    end)
  end

  defp default_list_items do
    [
      %{
        "title" => "{{item.title}}",
        "meta" => "{{item.category}}",
        "body" => "{{item.excerpt}}"
      },
      %{"title" => "Another item", "meta" => "Draft", "body" => "Map any field into this row."}
    ]
  end

  defp default_table_items do
    [
      %{"title" => "Pressure Cooker", "status" => "Published", "updated_at" => "Today"},
      %{"title" => "Customer Review", "status" => "Draft", "updated_at" => "Yesterday"}
    ]
  end

  defp tab_items(props) do
    props
    |> Map.get("tabs", [
      %{"id" => "overview", "label" => "Overview", "body" => "Overview content"},
      %{"id" => "details", "label" => "Details", "body" => "Details content"},
      %{"id" => "settings", "label" => "Settings", "body" => "Settings content"}
    ])
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      %{
        id: item["id"] || item["label"] || "tab_#{index}",
        index: index,
        label: item["label"] || "Tab",
        body: item["body"] || ""
      }
    end)
  end

  defp active_tab(props) do
    props["active_item"] || props["active_tab"] ||
      props |> tab_items() |> List.first(%{}) |> Map.get(:id, "overview")
  end

  defp tabs_align("center"), do: "justify-center"
  defp tabs_align("end"), do: "justify-end"
  defp tabs_align(_align), do: "justify-start"

  defp tabs_responsive(true), do: "max-sm:tabs-vertical"
  defp tabs_responsive("true"), do: "max-sm:tabs-vertical"
  defp tabs_responsive(_responsive), do: ""
end
