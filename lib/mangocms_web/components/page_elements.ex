defmodule MangoCMSWeb.PageElements do
  @moduledoc """
  Stateless presentation elements for MangoCMS content-tree nodes.

  These components know how to render markup from standardized `props` and
  categorized `classes`, but they do not know whether they are used in the
  public viewport or the admin canvas.
  """

  use MangoCMSWeb, :html

  # ---------------------------------------------------------------------------
  # Shared rendering primitives
  # ---------------------------------------------------------------------------

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}
  slot :inner_block

  @doc "Renders a full-width page section wrapper."
  @spec section(map()) :: Phoenix.LiveView.Rendered.t()
  def section(assigns) do
    ~H"""
    <section class={class_names(@classes, "w-full")}>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}
  slot :inner_block

  @doc "Renders an inner row/grid wrapper."
  @spec row(map()) :: Phoenix.LiveView.Rendered.t()
  def row(assigns) do
    ~H"""
    <div class={
      class_names(
        @classes,
        "mx-auto grid w-full max-w-7xl grid-cols-12 gap-6 px-4 py-8 sm:px-6 lg:px-8"
      )
    }>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}
  slot :inner_block

  @doc "Renders a column container inside a row."
  @spec column(map()) :: Phoenix.LiveView.Rendered.t()
  def column(assigns) do
    ~H"""
    <div class={class_names(@classes, "col-span-12")}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Typography and media elements
  # ---------------------------------------------------------------------------

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}

  @doc "Renders a heading element from props."
  @spec heading(map()) :: Phoenix.LiveView.Rendered.t()
  def heading(assigns) do
    assigns = assign(assigns, :level, heading_level(assigns.props))

    ~H"""
    <%= case @level do %>
      <% 1 -> %>
        <h1 class={
          class_names(@classes, "text-4xl font-bold tracking-tight text-base-content sm:text-5xl")
        }>
          {prop(@props, "text", "Untitled heading")}
        </h1>
      <% 2 -> %>
        <h2 class={class_names(@classes, "text-3xl font-bold tracking-tight text-base-content")}>
          {prop(@props, "text", "Untitled heading")}
        </h2>
      <% 3 -> %>
        <h3 class={class_names(@classes, "text-2xl font-semibold text-base-content")}>
          {prop(@props, "text", "Untitled heading")}
        </h3>
      <% 4 -> %>
        <h4 class={class_names(@classes, "text-xl font-semibold text-base-content")}>
          {prop(@props, "text", "Untitled heading")}
        </h4>
      <% 5 -> %>
        <h5 class={class_names(@classes, "text-lg font-semibold text-base-content")}>
          {prop(@props, "text", "Untitled heading")}
        </h5>
      <% _ -> %>
        <h6 class={class_names(@classes, "text-base font-semibold text-base-content")}>
          {prop(@props, "text", "Untitled heading")}
        </h6>
    <% end %>
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}

  @doc "Renders paragraph text."
  @spec paragraph(map()) :: Phoenix.LiveView.Rendered.t()
  def paragraph(assigns) do
    ~H"""
    <p class={class_names(@classes, "text-base leading-7 text-base-content/75")}>
      {prop(@props, "text", "Add paragraph text.")}
    </p>
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}

  @doc "Renders a blockquote."
  @spec blockquote(map()) :: Phoenix.LiveView.Rendered.t()
  def blockquote(assigns) do
    ~H"""
    <blockquote class={
      class_names(@classes, "border-l-4 border-primary pl-4 text-lg italic text-base-content/80")
    }>
      {prop(@props, "text", "Add a quote.")}
    </blockquote>
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}

  @doc "Renders an image with optional link wrapping."
  @spec image(map()) :: Phoenix.LiveView.Rendered.t()
  def image(assigns) do
    assigns =
      assigns
      |> assign(:src, prop(assigns.props, "src", prop(assigns.props, "image_url", "")))
      |> assign(:alt, prop(assigns.props, "alt", ""))
      |> assign(:href, prop(assigns.props, "href", ""))
      |> assign(:target, link_target(assigns.props))

    ~H"""
    <.link :if={@href != ""} href={@href} target={@target}>
      <img src={@src} alt={@alt} class={class_names(@classes, "w-full rounded-lg object-cover")} />
    </.link>
    <img
      :if={@href == ""}
      src={@src}
      alt={@alt}
      class={class_names(@classes, "w-full rounded-lg object-cover")}
    />
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}

  @doc "Renders a video wrapper."
  @spec video(map()) :: Phoenix.LiveView.Rendered.t()
  def video(assigns) do
    assigns =
      assigns
      |> assign(:src, prop(assigns.props, "src", ""))
      |> assign(:title, prop(assigns.props, "title", "Video"))

    ~H"""
    <div class={class_names(@classes, "aspect-video overflow-hidden rounded-lg bg-base-200")}>
      <iframe
        :if={@src != ""}
        src={@src}
        title={@title}
        class="size-full"
        loading="lazy"
        allowfullscreen
      >
      </iframe>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Interactive elements
  # ---------------------------------------------------------------------------

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}

  @doc "Renders a button-style link."
  @spec button(map()) :: Phoenix.LiveView.Rendered.t()
  def button(assigns) do
    assigns =
      assigns
      |> assign(:href, prop(assigns.props, "href", "#"))
      |> assign(:target, link_target(assigns.props))

    ~H"""
    <.link href={@href} target={@target} class={class_names(@classes, "btn btn-primary")}>
      {prop(@props, "text", "Button")}
    </.link>
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}

  @doc "Renders a plain anchor link."
  @spec anchor(map()) :: Phoenix.LiveView.Rendered.t()
  def anchor(assigns) do
    assigns =
      assigns
      |> assign(:href, prop(assigns.props, "href", "#"))
      |> assign(:target, link_target(assigns.props))
      |> assign(:title, prop(assigns.props, "title", ""))

    ~H"""
    <.link
      href={@href}
      target={@target}
      title={@title}
      class={class_names(@classes, "link link-primary")}
    >
      {prop(@props, "text", "Link")}
    </.link>
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}

  @doc "Renders a small dynamic form placeholder."
  @spec dynamic_form(map()) :: Phoenix.LiveView.Rendered.t()
  def dynamic_form(assigns) do
    ~H"""
    <form class={class_names(@classes, "card bg-base-100 p-4 shadow-sm")}>
      <label class="form-control">
        <span class="label-text">{prop(@props, "label", "Email")}</span>
        <input
          type="email"
          class="input input-bordered"
          placeholder={prop(@props, "placeholder", "you@example.com")}
        />
      </label>
      <button type="submit" class="btn btn-primary mt-3">
        {prop(@props, "submit_label", "Submit")}
      </button>
    </form>
    """
  end

  attr :props, :map, default: %{}
  attr :classes, :map, default: %{}
  slot :inner_block

  @doc "Renders unknown nodes in a harmless wrapper."
  @spec unknown(map()) :: Phoenix.LiveView.Rendered.t()
  def unknown(assigns) do
    ~H"""
    <div class={
      class_names(
        @classes,
        "rounded-lg border border-dashed border-base-300 p-4 text-sm text-base-content/60"
      )
    }>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Combines categorized class strings into one class list."
  @spec class_names(map(), String.t()) :: [String.t()]
  def class_names(classes, fallback) when is_map(classes) do
    [
      class_value(classes, "display", fallback),
      class_value(classes, "daisy_ui", ""),
      class_value(classes, "padding", ""),
      class_value(classes, "margin", ""),
      class_value(classes, "custom", "")
    ]
  end

  def class_names(_classes, fallback), do: [fallback]

  @doc "Fetches a string prop with a fallback."
  @spec prop(map(), String.t(), String.t()) :: String.t()
  def prop(props, key, fallback) when is_map(props) do
    case Map.get(props, key) do
      value when is_binary(value) -> value
      value when is_integer(value) -> Integer.to_string(value)
      _other -> fallback
    end
  end

  def prop(_props, _key, fallback), do: fallback

  defp class_value(classes, key, fallback) do
    case Map.get(classes, key) do
      value when is_binary(value) and value != "" -> value
      _other -> fallback
    end
  end

  defp heading_level(props) do
    props
    |> prop("level", "2")
    |> Integer.parse()
    |> case do
      {level, ""} when level in 1..6 -> level
      _other -> 2
    end
  end

  defp link_target(props) do
    case prop(props, "target", "_self") do
      "_blank" -> "_blank"
      _other -> "_self"
    end
  end
end
