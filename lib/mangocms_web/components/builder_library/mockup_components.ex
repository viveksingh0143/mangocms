defmodule MangoCMSWeb.BuilderLibrary.MockupComponents do
  @moduledoc """
  Pure Phoenix renderers for builder mockup components.
  """

  use MangoCMSWeb, :html

  # ── Browser mockup ────────────────────────────────────────────────────────────

  @doc "Renders a browser chrome mockup."
  @spec mockup_browser(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def mockup_browser(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "mockup-browser shadow-xl",
      browser_chrome(@props["theme"]),
      class_value(@classes, "custom")
    ]}>
      <div class="mockup-browser-toolbar">
        <div class={["input text-sm", browser_toolbar_input(@props["theme"])]}>
          {@props["url"] || "https://example.com"}
        </div>
      </div>
      <div class={["min-h-32 p-6", browser_body(@props["theme"])]}>
        <p class="text-sm opacity-50 italic">
          {if @props["placeholder"] not in [nil, ""],
            do: @props["placeholder"],
            else: "Drop content here"}
        </p>
      </div>
    </div>
    """
  end

  # ── Code mockup ───────────────────────────────────────────────────────────────

  @doc "Renders a terminal / code block mockup."
  @spec mockup_code(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def mockup_code(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "mockup-code shadow-xl",
      code_theme(@props["theme"]),
      class_value(@classes, "custom")
    ]}>
      <pre
        :for={line <- parse_code_lines(@props["lines"])}
        data-prefix={line.prefix}
        class={line_tone_class(line.tone)}
      ><code>{line.code}</code></pre>
    </div>
    """
  end

  # ── Phone mockup ──────────────────────────────────────────────────────────────

  @doc "Renders a phone device mockup."
  @spec mockup_phone(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def mockup_phone(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["mockup-phone", class_value(@classes, "custom")]}>
      <div class="camera"></div>
      <div class="display">
        <div class={[
          "artboard artboard-demo",
          phone_size(@props["size"]),
          phone_screen_bg(@props["screen_bg"])
        ]}>
          <p class="text-sm opacity-50 italic">
            {if @props["placeholder"] not in [nil, ""],
              do: @props["placeholder"],
              else: "Phone screen content"}
          </p>
        </div>
      </div>
    </div>
    """
  end

  # ── Window mockup ─────────────────────────────────────────────────────────────

  @doc "Renders a desktop window chrome mockup."
  @spec mockup_window(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def mockup_window(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "mockup-window shadow-xl",
      window_chrome(@props["theme"]),
      class_value(@classes, "custom")
    ]}>
      <div class={["min-h-32 border-t p-6", window_body(@props["theme"])]}>
        <p class="text-sm opacity-50 italic">
          {if @props["placeholder"] not in [nil, ""],
            do: @props["placeholder"],
            else: "Drop content here"}
        </p>
      </div>
    </div>
    """
  end

  # ── Private helpers ───────────────────────────────────────────────────────────

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""

  defp browser_chrome("dark"), do: "bg-neutral text-neutral-content border border-neutral"
  defp browser_chrome(_theme), do: "bg-base-300 border border-base-300"

  defp browser_toolbar_input("dark"),
    do: "border border-neutral bg-neutral-content/10 text-neutral-content"

  defp browser_toolbar_input(_theme), do: "border border-base-300 bg-base-100"

  defp browser_body("dark"), do: "bg-neutral/80"
  defp browser_body(_theme), do: "bg-base-100"

  defp code_theme("light"), do: "bg-base-200 text-base-content"
  defp code_theme(_theme), do: "bg-neutral text-neutral-content"

  defp phone_size("2"), do: "phone-2"
  defp phone_size("3"), do: "phone-3"
  defp phone_size("4"), do: "phone-4"
  defp phone_size(_size), do: "phone-1"

  defp phone_screen_bg("primary"), do: "bg-primary text-primary-content"
  defp phone_screen_bg("neutral"), do: "bg-neutral text-neutral-content"
  defp phone_screen_bg(_bg), do: "bg-base-100"

  defp window_chrome("dark"), do: "bg-neutral text-neutral-content border border-neutral"
  defp window_chrome(_theme), do: "bg-base-300 border border-base-300"

  defp window_body("dark"), do: "border-neutral bg-neutral/80"
  defp window_body(_theme), do: "border-base-300 bg-base-100"

  @doc false
  def parse_code_lines(nil), do: default_code_lines()
  def parse_code_lines(""), do: default_code_lines()

  def parse_code_lines(lines_str) when is_binary(lines_str) do
    parsed =
      lines_str
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_code_line/1)

    if parsed == [], do: default_code_lines(), else: parsed
  end

  def parse_code_lines(_), do: default_code_lines()

  defp parse_code_line(line) do
    case String.split(line, "|", parts: 3) do
      [prefix, code, tone] -> %{prefix: prefix, code: code, tone: String.trim(tone)}
      [prefix, code] -> %{prefix: prefix, code: code, tone: ""}
      [code] -> %{prefix: "$", code: code, tone: ""}
    end
  end

  defp default_code_lines do
    [
      %{prefix: "$", code: "mix phx.server", tone: ""},
      %{prefix: ">", code: "starting server on port 4000", tone: ""},
      %{prefix: ">", code: "access at http://localhost:4000", tone: "info"},
      %{prefix: "✓", code: "ready", tone: "success"}
    ]
  end

  defp line_tone_class("success"), do: "text-success"
  defp line_tone_class("error"), do: "text-error"
  defp line_tone_class("warning"), do: "text-warning"
  defp line_tone_class("info"), do: "text-info"
  defp line_tone_class(_tone), do: nil
end
