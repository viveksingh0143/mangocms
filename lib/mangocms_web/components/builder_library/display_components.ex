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
        <img src={@props["image_src"] || "/images/no-image-placeholder.webp"} alt={@props["image_alt"] || ""} />
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
        <img src={@props["image_src"] || "/images/no-image-placeholder.webp"} alt={@props["image_alt"] || ""} />
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

  # ── Batch 2 ──────────────────────────────────────────────────────────────────

  @doc "Renders an avatar or avatar group."
  @spec avatar(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :image

  def avatar(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:image, fn -> [] end)

    ~H"""
    <%= if @props["variant"] == "group" do %>
      <div class={["avatar-group -space-x-6 rtl:space-x-reverse", class_value(@classes, "custom")]}>
        <div :for={_ <- 1..avatar_count(@props)} class="avatar">
          <div class={["rounded-full", avatar_size(@props["size"])]}>
            <img
              src={@props["image_src"] || "/images/no-image-placeholder.webp"}
              alt={@props["alt"] || ""}
            />
          </div>
        </div>
      </div>
    <% else %>
      <div class={[
        "avatar",
        avatar_placeholder_cls(@props["image_src"]),
        avatar_status_cls(@props["status"]),
        class_value(@classes, "custom")
      ]}>
        <div class={[
          avatar_size(@props["size"]),
          avatar_shape(@props["shape"]),
          avatar_placeholder_bg(@props["image_src"])
        ]}>
          <%= if @image != [] do %>
            {render_slot(@image)}
          <% else %>
            <%= if @props["image_src"] not in [nil, ""] do %>
              <img src={@props["image_src"]} alt={@props["alt"] || ""} />
            <% else %>
              <span class="text-xl font-bold">{@props["initials"] || "A"}</span>
            <% end %>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  @doc "Renders a badge label."
  @spec badge(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :inner

  def badge(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:inner, fn -> [] end)

    ~H"""
    <span class={[
      "badge",
      badge_tone(@props["tone"]),
      badge_size(@props["size"]),
      badge_variant(@props["style"]),
      class_value(@classes, "custom")
    ]}>
      <%= if @inner != [] do %>
        {render_slot(@inner)}
      <% else %>
        {@props["label"] || "Badge"}
      <% end %>
    </span>
    """
  end

  @doc "Renders a chat bubble."
  @spec chat_bubble(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :content

  def chat_bubble(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:content, fn -> [] end)

    ~H"""
    <div class={[chat_align(@props["align"]), class_value(@classes, "custom")]}>
      <div :if={@props["avatar_enabled"] == true} class="chat-image avatar">
        <div class="w-10 rounded-full">
          <img
            src={@props["avatar_src"] || "/images/no-image-placeholder.webp"}
            alt={@props["avatar_alt"] || ""}
          />
        </div>
      </div>
      <div :if={@props["header"] not in [nil, ""]} class="chat-header">
        {@props["header"]}
        <time :if={@props["time"] not in [nil, ""]} class="text-xs opacity-50">
          {@props["time"]}
        </time>
      </div>
      <div class={["chat-bubble", chat_tone(@props["tone"])]}>
        <%= if @content != [] do %>
          {render_slot(@content)}
        <% else %>
          {@props["message"] || "Chat message"}
        <% end %>
      </div>
      <div :if={@props["footer"] not in [nil, ""]} class="chat-footer text-xs opacity-50">
        {@props["footer"]}
      </div>
    </div>
    """
  end

  @doc "Renders an Alpine-powered countdown timer."
  @spec countdown(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def countdown(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      class={["flex gap-5 font-mono text-center", class_value(@classes, "custom")]}
      x-data={countdown_xdata(@props)}
      x-init="tick()"
    >
      <div :if={@props["show_days"] == true} class="flex flex-col items-center">
        <span class="countdown text-5xl font-bold">
          <span x-bind:style="'--value:' + dd"></span>
        </span>
        <span class="mt-1 text-xs uppercase opacity-70">{@props["label_days"] || "days"}</span>
      </div>
      <div class="flex flex-col items-center">
        <span class="countdown text-5xl font-bold">
          <span x-bind:style="'--value:' + hh"></span>
        </span>
        <span class="mt-1 text-xs uppercase opacity-70">{@props["label_hours"] || "hours"}</span>
      </div>
      <div class="flex flex-col items-center">
        <span class="countdown text-5xl font-bold">
          <span x-bind:style="'--value:' + mm"></span>
        </span>
        <span class="mt-1 text-xs uppercase opacity-70">{@props["label_minutes"] || "min"}</span>
      </div>
      <div class="flex flex-col items-center">
        <span class="countdown text-5xl font-bold">
          <span x-bind:style="'--value:' + ss"></span>
        </span>
        <span class="mt-1 text-xs uppercase opacity-70">{@props["label_seconds"] || "sec"}</span>
      </div>
    </div>
    """
  end

  @doc "Renders a side-by-side diff slider."
  @spec diff(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def diff(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["diff aspect-video rounded-box", class_value(@classes, "custom")]}>
      <div class="diff-item-1">
        <%= if @props["type"] == "text" do %>
          <div class="grid size-full place-content-center bg-base-200 text-6xl font-black">
            {@props["before_text"] || "Before"}
          </div>
        <% else %>
          <img
            src={@props["before_src"] || "/images/no-image-placeholder.webp"}
            alt={@props["before_alt"] || "Before"}
            class="size-full object-cover"
          />
        <% end %>
      </div>
      <div class="diff-item-2">
        <%= if @props["type"] == "text" do %>
          <div class="grid size-full place-content-center bg-base-content text-6xl font-black text-base-100">
            {@props["after_text"] || "After"}
          </div>
        <% else %>
          <img
            src={@props["after_src"] || "/images/no-image-placeholder.webp"}
            alt={@props["after_alt"] || "After"}
            class="size-full object-cover"
          />
        <% end %>
      </div>
      <div class="diff-resizer"></div>
    </div>
    """
  end

  @doc "Renders a 3D tilt card powered by Alpine mouse tracking."
  @spec hover_3d_card(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :content

  def hover_3d_card(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:content, fn -> [] end)

    ~H"""
    <div
      class={["group", card_3d_size(@props["size"]), class_value(@classes, "custom")]}
      style="perspective: 1000px"
      x-data={tilt3d_xdata()}
      x-on:mousemove="tilt($event)"
      x-on:mouseleave="reset()"
    >
      <div
        class="card bg-base-100 shadow-xl transition-transform duration-200 ease-out"
        x-bind:style="{ transform: tiltCss }"
      >
        <figure :if={@props["image_src"] not in [nil, ""]}>
          <img
            src={@props["image_src"]}
            alt={@props["image_alt"] || ""}
            class="w-full object-cover"
          />
        </figure>
        <div class="card-body">
          <%= if @content != [] do %>
            {render_slot(@content)}
          <% else %>
            <h2 class="card-title">{@props["title"] || "3D Card"}</h2>
            <p class="text-sm text-base-content/70">
              {@props["body"] || "Hover to tilt this card in 3D space."}
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc "Renders an image gallery with CSS hover zoom."
  @spec hover_gallery(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :items

  def hover_gallery(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:items, fn -> [] end)

    ~H"""
    <div class={[
      "grid",
      gallery_columns(@props["columns"]),
      gallery_gap(@props["gap"]),
      class_value(@classes, "custom")
    ]}>
      <%= if @items != [] do %>
        {render_slot(@items)}
      <% else %>
        <div :for={item <- gallery_items(@props)} class="group overflow-hidden rounded-box">
          <img
            src={item["src"] || "/images/no-image-placeholder.webp"}
            alt={item["alt"] || ""}
            class={[
              "h-48 w-full object-cover transition-transform duration-500 ease-out",
              gallery_hover_class(@props["effect"])
            ]}
          />
          <p :if={item["caption"] not in [nil, ""]} class="mt-1 text-center text-sm opacity-70">
            {item["caption"]}
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  @doc "Renders keyboard key badges."
  @spec kbd(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def kbd(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["flex flex-wrap items-center gap-1", class_value(@classes, "custom")]}>
      <kbd :for={key <- kbd_keys(@props)} class={["kbd", kbd_size(@props["size"])]}>
        {key}
      </kbd>
    </div>
    """
  end

  @doc "Renders a status indicator dot with optional label."
  @spec status(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def status(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["inline-flex items-center gap-2", class_value(@classes, "custom")]}>
      <span class={["status", status_tone(@props["tone"]), status_size(@props["size"])]}></span>
      <span :if={@props["label"] not in [nil, ""]} class="text-sm">{@props["label"]}</span>
    </div>
    """
  end

  @doc "Renders Alpine-powered rotating text."
  @spec text_rotate(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def text_rotate(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      class={["flex flex-wrap items-baseline gap-2", class_value(@classes, "custom")]}
      x-data={text_rotate_xdata(@props)}
      x-init="start()"
    >
      <span :if={@props["prefix"] not in [nil, ""]} class={[rotate_size(@props["size"])]}>
        {@props["prefix"]}
      </span>
      <span
        class={["font-bold text-primary", rotate_size(@props["size"])]}
        x-text="words[idx]"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0 -translate-y-2"
        x-transition:enter-end="opacity-100 translate-y-0"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="opacity-100 translate-y-0"
        x-transition:leave-end="opacity-0 translate-y-2"
      >
        {List.first(rotate_words(@props)) || "word"}
      </span>
      <span :if={@props["suffix"] not in [nil, ""]} class={[rotate_size(@props["size"])]}>
        {@props["suffix"]}
      </span>
    </div>
    """
  end

  # ── Batch 2 helpers ───────────────────────────────────────────────────────────

  defp avatar_placeholder_cls(src) when src in [nil, ""], do: "placeholder"
  defp avatar_placeholder_cls(_src), do: nil

  defp avatar_placeholder_bg(src) when src in [nil, ""], do: "bg-neutral text-neutral-content"
  defp avatar_placeholder_bg(_src), do: nil

  defp avatar_size("xs"), do: "w-8"
  defp avatar_size("sm"), do: "w-12"
  defp avatar_size("lg"), do: "w-20"
  defp avatar_size("xl"), do: "w-32"
  defp avatar_size(_size), do: "w-16"

  defp avatar_shape("rounded"), do: "rounded-lg"
  defp avatar_shape("square"), do: "rounded-none"
  defp avatar_shape(_shape), do: "rounded-full"

  defp avatar_status_cls("online"), do: "avatar-online"
  defp avatar_status_cls("offline"), do: "avatar-offline"
  defp avatar_status_cls("away"), do: "avatar-away"
  defp avatar_status_cls("busy"), do: "avatar-busy"
  defp avatar_status_cls(_status), do: nil

  defp avatar_count(%{"count" => count}) when is_integer(count) and count >= 1, do: min(count, 8)
  defp avatar_count(_props), do: 3

  defp badge_tone("primary"), do: "badge-primary"
  defp badge_tone("secondary"), do: "badge-secondary"
  defp badge_tone("accent"), do: "badge-accent"
  defp badge_tone("neutral"), do: "badge-neutral"
  defp badge_tone("success"), do: "badge-success"
  defp badge_tone("warning"), do: "badge-warning"
  defp badge_tone("error"), do: "badge-error"
  defp badge_tone("info"), do: "badge-info"
  defp badge_tone("ghost"), do: "badge-ghost"
  defp badge_tone(_tone), do: ""

  defp badge_size("xs"), do: "badge-xs"
  defp badge_size("sm"), do: "badge-sm"
  defp badge_size("lg"), do: "badge-lg"
  defp badge_size("xl"), do: "badge-xl"
  defp badge_size(_size), do: ""

  defp badge_variant("outline"), do: "badge-outline"
  defp badge_variant("soft"), do: "badge-soft"
  defp badge_variant("dash"), do: "badge-dash"
  defp badge_variant(_style), do: ""

  defp chat_align("end"), do: "chat chat-end"
  defp chat_align(_align), do: "chat chat-start"

  defp chat_tone("primary"), do: "chat-bubble-primary"
  defp chat_tone("secondary"), do: "chat-bubble-secondary"
  defp chat_tone("accent"), do: "chat-bubble-accent"
  defp chat_tone("neutral"), do: "chat-bubble-neutral"
  defp chat_tone("info"), do: "chat-bubble-info"
  defp chat_tone("success"), do: "chat-bubble-success"
  defp chat_tone("warning"), do: "chat-bubble-warning"
  defp chat_tone("error"), do: "chat-bubble-error"
  defp chat_tone(_tone), do: ""

  defp countdown_xdata(props) do
    secs = countdown_seconds(props)
    dd = div(secs, 86_400)
    hh = div(rem(secs, 86_400), 3_600)
    mm = div(rem(secs, 3_600), 60)
    ss = rem(secs, 60)

    "{ dd: #{dd}, hh: #{hh}, mm: #{mm}, ss: #{ss}, remaining: #{secs}," <>
      " tick() { setInterval(() => { if (this.remaining > 0) {" <>
      " this.remaining--;" <>
      " this.dd = Math.floor(this.remaining / 86400);" <>
      " this.hh = Math.floor(this.remaining % 86400 / 3600);" <>
      " this.mm = Math.floor(this.remaining % 3600 / 60);" <>
      " this.ss = this.remaining % 60; } }, 1000); } }"
  end

  defp countdown_seconds(%{"target_seconds" => s}) when is_integer(s) and s > 0, do: s

  defp countdown_seconds(%{"target_seconds" => s}) when is_binary(s) do
    case Integer.parse(s) do
      {int, _} when int > 0 -> int
      _ -> 3_661
    end
  end

  defp countdown_seconds(_props), do: 3_661

  defp tilt3d_xdata do
    "{ tiltCss: ''," <>
      " tilt(e) { const r = this.$el.getBoundingClientRect();" <>
      " const x = (e.clientY - r.top) / r.height - 0.5;" <>
      " const y = (e.clientX - r.left) / r.width - 0.5;" <>
      " this.tiltCss = 'perspective(1000px) rotateX(' + (-x * 20) + 'deg) rotateY(' + (y * 20) + 'deg)'; }," <>
      " reset() { this.tiltCss = ''; } }"
  end

  defp card_3d_size("sm"), do: "w-full max-w-xs"
  defp card_3d_size("lg"), do: "w-full max-w-lg"
  defp card_3d_size(_size), do: "w-full max-w-sm"

  defp gallery_columns("2"), do: "grid-cols-2"
  defp gallery_columns("3"), do: "grid-cols-3"
  defp gallery_columns("4"), do: "grid-cols-4"
  defp gallery_columns("5"), do: "grid-cols-5"
  defp gallery_columns(2), do: "grid-cols-2"
  defp gallery_columns(3), do: "grid-cols-3"
  defp gallery_columns(4), do: "grid-cols-4"
  defp gallery_columns(5), do: "grid-cols-5"
  defp gallery_columns(_columns), do: "grid-cols-3"

  defp gallery_gap("sm"), do: "gap-2"
  defp gallery_gap("lg"), do: "gap-6"
  defp gallery_gap(_gap), do: "gap-4"

  defp gallery_hover_class("zoom_out"), do: "group-hover:scale-90"
  defp gallery_hover_class("brightness"), do: "group-hover:brightness-125"
  defp gallery_hover_class("grayscale"), do: "grayscale group-hover:grayscale-0"
  defp gallery_hover_class(_effect), do: "group-hover:scale-110"

  defp gallery_items(%{"items" => items}) when is_list(items) and items != [], do: items

  defp gallery_items(_props) do
    [
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Photo 1", "caption" => "Gallery item"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Photo 2"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Photo 3"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Photo 4"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Photo 5"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Photo 6"}
    ]
  end

  defp kbd_keys(%{"keys" => keys}) when is_list(keys) and keys != [], do: keys

  defp kbd_keys(%{"keys" => keys}) when is_binary(keys) and keys != "" do
    keys |> String.split("+") |> Enum.map(&String.trim/1)
  end

  defp kbd_keys(_props), do: ["ctrl", "K"]

  defp kbd_size("xs"), do: "kbd-xs"
  defp kbd_size("sm"), do: "kbd-sm"
  defp kbd_size("lg"), do: "kbd-lg"
  defp kbd_size("xl"), do: "kbd-xl"
  defp kbd_size(_size), do: ""

  defp status_tone("success"), do: "status-success"
  defp status_tone("warning"), do: "status-warning"
  defp status_tone("error"), do: "status-error"
  defp status_tone("info"), do: "status-info"
  defp status_tone("primary"), do: "status-primary"
  defp status_tone("secondary"), do: "status-secondary"
  defp status_tone("accent"), do: "status-accent"
  defp status_tone("neutral"), do: "status-neutral"
  defp status_tone(_tone), do: ""

  defp status_size("xs"), do: "status-xs"
  defp status_size("sm"), do: "status-sm"
  defp status_size("lg"), do: "status-lg"
  defp status_size("xl"), do: "status-xl"
  defp status_size(_size), do: ""

  defp rotate_words(%{"words" => words}) when is_list(words) and words != [], do: words

  defp rotate_words(%{"words" => words}) when is_binary(words) and words != "" do
    words |> String.split(",") |> Enum.map(&String.trim/1)
  end

  defp rotate_words(_props), do: ["fast", "scalable", "composable"]

  defp rotate_size("sm"), do: "text-xl"
  defp rotate_size("lg"), do: "text-5xl"
  defp rotate_size("xl"), do: "text-7xl"
  defp rotate_size(_size), do: "text-3xl"

  defp text_rotate_xdata(props) do
    words = rotate_words(props)
    interval = props["interval_ms"] || 2_000

    words_js =
      "[" <>
        Enum.map_join(words, ", ", fn w ->
          ~s("#{String.replace(w, "\"", "\\\"")}")
        end) <> "]"

    "{ words: #{words_js}, idx: 0," <>
      " start() { setInterval(() => { this.idx = (this.idx + 1) % this.words.length; }, #{interval}); } }"
  end
end
