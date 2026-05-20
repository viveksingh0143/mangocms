defmodule MangoCMSWeb.BuilderLibrary.TypographyComponents do
  @moduledoc """
  Pure Phoenix renderers for builder typography components.
  """

  use MangoCMSWeb, :html

  @doc "Renders an h1–h6 heading based on the level prop."
  @spec heading(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def heading(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <%= case to_string(@props["level"] || "1") do %>
      <% "2" -> %>
        <h2 class={heading_classes(@props, @classes)}>{@props["text"] || "Heading"}</h2>
      <% "3" -> %>
        <h3 class={heading_classes(@props, @classes)}>{@props["text"] || "Heading"}</h3>
      <% "4" -> %>
        <h4 class={heading_classes(@props, @classes)}>{@props["text"] || "Heading"}</h4>
      <% "5" -> %>
        <h5 class={heading_classes(@props, @classes)}>{@props["text"] || "Heading"}</h5>
      <% "6" -> %>
        <h6 class={heading_classes(@props, @classes)}>{@props["text"] || "Heading"}</h6>
      <% _ -> %>
        <h1 class={heading_classes(@props, @classes)}>{@props["text"] || "Heading"}</h1>
    <% end %>
    """
  end

  @doc "Renders a paragraph block."
  @spec paragraph(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def paragraph(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <p class={[
      para_size_class(@props["size"]),
      text_align_class(@props["align"]),
      max_width_class(@props["max_width"]),
      text_color_class(@props["color"]),
      class_value(@classes, "custom")
    ]}>
      {@props["body"] || "Paragraph text. Click to edit."}
    </p>
    """
  end

  @doc "Renders raw HTML/markdown body content."
  @spec rich_text(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def rich_text(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "prose max-w-none",
      max_width_class(@props["max_width"]),
      class_value(@classes, "custom")
    ]}>
      {Phoenix.HTML.raw(@props["content"] || "<p>Add your rich text content here.</p>")}
    </div>
    """
  end

  @doc "Renders a styled blockquote."
  @spec blockquote(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def blockquote(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <figure class={[
      "border-l-4 border-primary pl-6 py-2",
      class_value(@classes, "custom")
    ]}>
      <blockquote class="text-lg italic text-base-content/80">
        <p>{@props["text"] || "An inspiring quote goes here."}</p>
      </blockquote>
      <figcaption
        :if={@props["author"] not in [nil, ""]}
        class="mt-3 text-sm font-semibold text-base-content/60"
      >
        — {@props["author"]}<span :if={@props["cite"] not in [nil, ""]}>, <cite class="not-italic">{@props["cite"]}</cite></span>
      </figcaption>
    </figure>
    """
  end

  @doc "Renders a syntax-highlighted code block."
  @spec code_block(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def code_block(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["rounded-xl overflow-hidden border border-base-300", class_value(@classes, "custom")]}>
      <div
        :if={@props["language"] not in [nil, ""]}
        class="flex items-center justify-between bg-neutral px-4 py-2"
      >
        <span class="font-mono text-xs text-neutral-content/60">{@props["language"]}</span>
      </div>
      <pre class="overflow-x-auto bg-neutral p-4 text-sm"><code class={code_lang_class(@props["language"])} >{@props["code"] || "// Add your code here"}</code></pre>
    </div>
    """
  end

  @doc "Renders an ordered list."
  @spec ordered_list(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def ordered_list(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <ol class={[
      "ml-6 space-y-1",
      ol_style_class(@props["style"]),
      class_value(@classes, "custom")
    ]}>
      <li :for={item <- list_items(@props)} class="text-base-content">
        {item_label(item)}
      </li>
    </ol>
    """
  end

  @doc "Renders an unordered list."
  @spec unordered_list(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def unordered_list(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <ul class={[
      "ml-6 space-y-1",
      ul_style_class(@props["style"]),
      class_value(@classes, "custom")
    ]}>
      <li :for={item <- list_items(@props)} class="text-base-content">
        {item_label(item)}
      </li>
    </ul>
    """
  end

  @doc "Renders inline text with a CSS gradient fill."
  @spec text_gradient(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def text_gradient(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <span
      class={[
        "inline-block bg-clip-text text-transparent",
        gradient_size_class(@props["size"]),
        gradient_weight_class(@props["weight"]),
        class_value(@classes, "custom")
      ]}
      style={gradient_style(@props)}
    >
      {@props["text"] || "Gradient text"}
    </span>
    """
  end

  @doc "Renders a small uppercase eyebrow / label span."
  @spec label_text(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def label_text(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <span class={[
      "inline-block font-semibold uppercase tracking-widest",
      label_size_class(@props["size"]),
      label_color_class(@props["color"]),
      class_value(@classes, "custom")
    ]}>
      {@props["text"] || "Label"}
    </span>
    """
  end

  # ── Private helpers ───────────────────────────────────────────────────────────

  defp heading_classes(props, classes) do
    [
      heading_size_class(props["size"] || props["level"]),
      heading_weight_class(props["weight"]),
      text_align_class(props["align"]),
      text_color_class(props["color"]),
      class_value(classes, "custom")
    ]
  end

  defp heading_size_class("xs"), do: "text-lg"
  defp heading_size_class("sm"), do: "text-xl"
  defp heading_size_class("md"), do: "text-2xl"
  defp heading_size_class("lg"), do: "text-3xl"
  defp heading_size_class("xl"), do: "text-4xl"
  defp heading_size_class("2xl"), do: "text-5xl"
  defp heading_size_class("3xl"), do: "text-6xl"
  defp heading_size_class("1"), do: "text-5xl"
  defp heading_size_class("2"), do: "text-4xl"
  defp heading_size_class("3"), do: "text-3xl"
  defp heading_size_class("4"), do: "text-2xl"
  defp heading_size_class("5"), do: "text-xl"
  defp heading_size_class("6"), do: "text-lg"
  defp heading_size_class(_), do: "text-3xl"

  defp heading_weight_class("thin"), do: "font-thin"
  defp heading_weight_class("light"), do: "font-light"
  defp heading_weight_class("normal"), do: "font-normal"
  defp heading_weight_class("medium"), do: "font-medium"
  defp heading_weight_class("semibold"), do: "font-semibold"
  defp heading_weight_class("extrabold"), do: "font-extrabold"
  defp heading_weight_class("black"), do: "font-black"
  defp heading_weight_class(_), do: "font-bold"

  defp para_size_class("xs"), do: "text-xs"
  defp para_size_class("sm"), do: "text-sm"
  defp para_size_class("lg"), do: "text-lg leading-relaxed"
  defp para_size_class("xl"), do: "text-xl leading-relaxed"
  defp para_size_class(_), do: "text-base leading-relaxed"

  defp text_align_class("center"), do: "text-center"
  defp text_align_class("right"), do: "text-right"
  defp text_align_class("justify"), do: "text-justify"
  defp text_align_class(_), do: ""

  defp max_width_class("xs"), do: "max-w-xs"
  defp max_width_class("sm"), do: "max-w-sm"
  defp max_width_class("md"), do: "max-w-md"
  defp max_width_class("lg"), do: "max-w-lg"
  defp max_width_class("xl"), do: "max-w-xl"
  defp max_width_class("2xl"), do: "max-w-2xl"
  defp max_width_class("3xl"), do: "max-w-3xl"
  defp max_width_class("prose"), do: "max-w-prose"
  defp max_width_class(_), do: ""

  defp text_color_class("primary"), do: "text-primary"
  defp text_color_class("secondary"), do: "text-secondary"
  defp text_color_class("accent"), do: "text-accent"
  defp text_color_class("muted"), do: "text-base-content/60"
  defp text_color_class("error"), do: "text-error"
  defp text_color_class("success"), do: "text-success"
  defp text_color_class("warning"), do: "text-warning"
  defp text_color_class(_), do: "text-base-content"

  defp code_lang_class(lang) when is_binary(lang) and lang != "", do: "language-#{lang}"
  defp code_lang_class(_), do: ""

  defp ol_style_class("alpha"), do: "list-[lower-alpha]"
  defp ol_style_class("roman"), do: "list-[lower-roman]"
  defp ol_style_class(_), do: "list-decimal"

  defp ul_style_class("circle"), do: "list-[circle]"
  defp ul_style_class("square"), do: "list-square"
  defp ul_style_class("none"), do: "list-none"
  defp ul_style_class(_), do: "list-disc"

  defp list_items(%{"items" => items}) when is_list(items) and items != [], do: items

  defp list_items(_props) do
    [
      %{"label" => "First item"},
      %{"label" => "Second item"},
      %{"label" => "Third item"}
    ]
  end

  defp item_label(%{"label" => label}) when is_binary(label) and label != "", do: label
  defp item_label(%{"text" => text}) when is_binary(text) and text != "", do: text
  defp item_label(_item), do: "List item"

  defp gradient_style(props) do
    from = props["from_color"] || "#6366f1"
    to = props["to_color"] || "#ec4899"
    dir = gradient_direction(props["direction"])
    "background-image: linear-gradient(#{dir}, #{from}, #{to});"
  end

  defp gradient_direction("to_right"), do: "to right"
  defp gradient_direction("to_bottom"), do: "to bottom"
  defp gradient_direction("diagonal"), do: "135deg"
  defp gradient_direction("diagonal_reverse"), do: "225deg"
  defp gradient_direction(_), do: "to right"

  defp gradient_size_class("sm"), do: "text-2xl"
  defp gradient_size_class("md"), do: "text-4xl"
  defp gradient_size_class("lg"), do: "text-5xl"
  defp gradient_size_class("xl"), do: "text-6xl"
  defp gradient_size_class("2xl"), do: "text-7xl"
  defp gradient_size_class(_), do: "text-3xl"

  defp gradient_weight_class("normal"), do: "font-normal"
  defp gradient_weight_class("semibold"), do: "font-semibold"
  defp gradient_weight_class("extrabold"), do: "font-extrabold"
  defp gradient_weight_class("black"), do: "font-black"
  defp gradient_weight_class(_), do: "font-bold"

  defp label_size_class("xs"), do: "text-[10px]"
  defp label_size_class("sm"), do: "text-xs"
  defp label_size_class("lg"), do: "text-sm"
  defp label_size_class(_), do: "text-xs"

  defp label_color_class("primary"), do: "text-primary"
  defp label_color_class("secondary"), do: "text-secondary"
  defp label_color_class("accent"), do: "text-accent"
  defp label_color_class("muted"), do: "text-base-content/50"
  defp label_color_class(_), do: "text-primary"

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""
end
