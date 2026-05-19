defmodule MangoCMSWeb.BuilderLibrary.FeedbackComponents do
  @moduledoc """
  Pure Phoenix renderers for builder feedback components.
  """

  use MangoCMSWeb, :html

  @doc "Renders a daisyUI alert."
  @spec alert(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :content
  slot :actions

  def alert(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:content, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)

    ~H"""
    <div
      role="alert"
      class={[
        "alert",
        tone_class("alert", @props["tone"]),
        alert_variant(@props["variant"]),
        alert_size(@props["size"]),
        class_value(@classes, "custom")
      ]}
    >
      <.icon :if={@props["icon"] not in [nil, ""]} name={@props["icon"]} class="size-5" />
      <div>
        <h3 :if={@props["title"] not in [nil, ""]} class="font-bold">{@props["title"]}</h3>
        <%= if @content != [] do %>
          {render_slot(@content)}
        <% else %>
          <div class="text-sm">{@props["message"] || "Alert message"}</div>
        <% end %>
      </div>
      <div :if={@actions != []} class="ml-auto flex gap-2">{render_slot(@actions)}</div>
    </div>
    """
  end

  @doc "Renders a daisyUI loading indicator."
  @spec loading(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def loading(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <span
      class={[
        "loading",
        loading_style(@props["style"]),
        loading_size(@props["size"]),
        text_tone(@props["tone"]),
        class_value(@classes, "custom")
      ]}
      aria-label={@props["label"] || "Loading"}
    >
    </span>
    """
  end

  @doc "Renders a progress bar."
  @spec progress(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def progress(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["grid gap-1", class_value(@classes, "custom")]}>
      <div :if={@props["label"] not in [nil, ""]} class="flex justify-between text-sm">
        <span>{@props["label"]}</span>
        <span>{@props["value"] || 0}%</span>
      </div>
      <progress
        class={["progress w-full", tone_class("progress", @props["tone"])]}
        value={@props["value"] || 0}
        max={@props["max"] || 100}
      >
      </progress>
    </div>
    """
  end

  @doc "Renders a radial progress indicator."
  @spec radial_progress(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def radial_progress(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      class={[
        "radial-progress",
        text_tone(@props["tone"]),
        radial_size(@props["size"]),
        class_value(@classes, "custom")
      ]}
      style={"--value:#{@props["value"] || 0}; --size:#{@props["diameter"] || "5rem"}; --thickness:#{@props["thickness"] || "0.45rem"};"}
      role="progressbar"
      aria-valuenow={@props["value"] || 0}
      aria-valuemin="0"
      aria-valuemax="100"
    >
      {@props["label"] || "#{@props["value"] || 0}%"}
    </div>
    """
  end

  @doc "Renders skeleton placeholders."
  @spec skeleton(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def skeleton(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["grid gap-3", skeleton_width(@props["width"]), class_value(@classes, "custom")]}>
      <div
        :for={row <- 1..row_count(@props)}
        class={["skeleton", skeleton_shape(@props["shape"]), skeleton_height(@props["size"], row)]}
      >
      </div>
    </div>
    """
  end

  @doc "Renders an Alpine-powered toast preview."
  @spec toast(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :content

  def toast(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:content, fn -> [] end)

    ~H"""
    <div
      class={["relative min-h-24", class_value(@classes, "custom")]}
      x-data="{ open: true }"
      x-init={"#{if @props["auto_close"] == true, do: "setTimeout(() => open = false, #{@props["duration_ms"] || 3000})", else: ""}"}
    >
      <div
        class={["toast", toast_position(@props["position"])]}
        x-show="open"
        x-transition
      >
        <div class={["alert", tone_class("alert", @props["tone"])]}>
          <%= if @content != [] do %>
            {render_slot(@content)}
          <% else %>
            <span>{@props["message"] || "Toast message"}</span>
          <% end %>
          <button type="button" class="btn btn-ghost btn-xs" x-on:click="open = false">
            Dismiss
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc "Renders a tooltip wrapper."
  @spec tooltip(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}
  slot :trigger

  def tooltip(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))
      |> assign_new(:trigger, fn -> [] end)

    ~H"""
    <span
      class={[
        "tooltip",
        tooltip_position(@props["position"]),
        tone_class("tooltip", @props["tone"]),
        class_value(@classes, "custom")
      ]}
      data-tip={@props["text"] || "Helpful detail"}
      x-data="{ focused: false }"
    >
      <%= if @trigger != [] do %>
        {render_slot(@trigger)}
      <% else %>
        <button type="button" class={["btn", @props["trigger_style"] || "btn-ghost"]}>
          {@props["label"] || "Hover me"}
        </button>
      <% end %>
    </span>
    """
  end

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""

  defp tone_class(prefix, "success"), do: "#{prefix}-success"
  defp tone_class(prefix, "warning"), do: "#{prefix}-warning"
  defp tone_class(prefix, "error"), do: "#{prefix}-error"
  defp tone_class(prefix, "info"), do: "#{prefix}-info"
  defp tone_class(prefix, "primary"), do: "#{prefix}-primary"
  defp tone_class(prefix, "secondary"), do: "#{prefix}-secondary"
  defp tone_class(_prefix, _tone), do: ""

  defp text_tone("success"), do: "text-success"
  defp text_tone("warning"), do: "text-warning"
  defp text_tone("error"), do: "text-error"
  defp text_tone("info"), do: "text-info"
  defp text_tone("primary"), do: "text-primary"
  defp text_tone("secondary"), do: "text-secondary"
  defp text_tone(_tone), do: ""

  defp alert_variant("soft"), do: "alert-soft"
  defp alert_variant("outline"), do: "alert-outline"
  defp alert_variant("dash"), do: "alert-dash"
  defp alert_variant(_variant), do: ""

  defp alert_size("sm"), do: "text-sm"
  defp alert_size("lg"), do: "text-lg"
  defp alert_size(_size), do: ""

  defp loading_style("spinner"), do: "loading-spinner"
  defp loading_style("dots"), do: "loading-dots"
  defp loading_style("ring"), do: "loading-ring"
  defp loading_style("ball"), do: "loading-ball"
  defp loading_style("bars"), do: "loading-bars"
  defp loading_style(_style), do: "loading-spinner"

  defp loading_size("xs"), do: "loading-xs"
  defp loading_size("sm"), do: "loading-sm"
  defp loading_size("lg"), do: "loading-lg"
  defp loading_size("xl"), do: "loading-xl"
  defp loading_size(_size), do: "loading-md"

  defp radial_size("sm"), do: "text-sm"
  defp radial_size("lg"), do: "text-lg"
  defp radial_size(_size), do: ""

  defp skeleton_width("narrow"), do: "max-w-sm"
  defp skeleton_width("wide"), do: "max-w-3xl"
  defp skeleton_width(_width), do: "w-full"

  defp skeleton_shape("circle"), do: "size-16 rounded-full"
  defp skeleton_shape(_shape), do: "w-full rounded-box"

  defp skeleton_height("sm", _row), do: "h-3"
  defp skeleton_height("lg", _row), do: "h-8"
  defp skeleton_height(_size, 1), do: "h-6"
  defp skeleton_height(_size, _row), do: "h-4"

  defp row_count(%{"rows" => rows}) when is_integer(rows) and rows > 0, do: rows
  defp row_count(_props), do: 3

  defp toast_position("top_start"), do: "toast-top toast-start"
  defp toast_position("top_end"), do: "toast-top toast-end"
  defp toast_position("bottom_start"), do: "toast-bottom toast-start"
  defp toast_position(_position), do: "toast-bottom toast-end"

  defp tooltip_position("top"), do: "tooltip-top"
  defp tooltip_position("bottom"), do: "tooltip-bottom"
  defp tooltip_position("left"), do: "tooltip-left"
  defp tooltip_position("right"), do: "tooltip-right"
  defp tooltip_position(_position), do: ""
end
