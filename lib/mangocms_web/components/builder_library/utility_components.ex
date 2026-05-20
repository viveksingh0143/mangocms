defmodule MangoCMSWeb.BuilderLibrary.UtilityComponents do
  @moduledoc """
  Pure Phoenix renderers for builder interactive/utility components.
  """

  use MangoCMSWeb, :html

  @doc "Renders a copy-to-clipboard button."
  @spec copy_button(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def copy_button(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      id={"copy-btn-#{Map.get(assigns.node, "id", "default")}"}
      phx-hook="AlpineInit"
      x-data={Jason.encode!(%{"copied" => false})}
      class={["inline-flex items-center gap-2", class_value(@classes, "custom")]}
    >
      <code
        :if={@props["show_value"] in [true, "true"] && @props["value"] not in [nil, ""]}
        class="rounded bg-base-200 px-2 py-1 text-sm font-mono"
      >
        {@props["value"]}
      </code>
      <button
        type="button"
        class={["btn btn-sm gap-1", copy_btn_style(@props["style"])]}
        x-on:click={"navigator.clipboard.writeText(#{Jason.encode!(@props["value"] || "")}); copied = true; setTimeout(() => copied = false, 2000)"}
        x-bind:class="copied && 'btn-success'"
      >
        <span x-show="!copied"><.icon name="hero-clipboard" class="size-4" /></span>
        <span x-show="copied"><.icon name="hero-check" class="size-4" /></span>
        <span x-show="!copied">{@props["label"] || "Copy"}</span>
        <span x-show="copied">{@props["copied_label"] || "Copied!"}</span>
      </button>
    </div>
    """
  end

  @doc "Renders a read-more expand/collapse block."
  @spec read_more(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def read_more(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      id={"read-more-#{Map.get(assigns.node, "id", "default")}"}
      phx-hook="AlpineInit"
      x-data={Jason.encode!(%{"expanded" => false})}
      class={class_value(@classes, "custom")}
    >
      <div
        class="overflow-hidden transition-all duration-300"
        x-bind:style={"expanded ? 'max-height: none' : 'max-height: #{read_more_preview_height(@props["preview_lines"])}px'"}
      >
        <div class="prose max-w-none text-base-content/80 leading-relaxed">
          {Phoenix.HTML.raw(
            @props["content"] || "<p>Add your content here. Only a preview is shown initially.</p>"
          )}
        </div>
      </div>
      <div
        x-show="!expanded"
        class="h-8 -mt-8 bg-gradient-to-t from-base-100 to-transparent pointer-events-none"
      >
      </div>
      <button
        type="button"
        class="btn btn-ghost btn-sm mt-2 gap-1"
        x-on:click="expanded = !expanded"
      >
        <span x-show="!expanded">{@props["more_label"] || "Read more"}</span>
        <span x-show="expanded">{@props["less_label"] || "Show less"}</span>
        <span x-bind:class="expanded && 'rotate-180'" class="inline-flex transition-transform">
          <.icon name="hero-chevron-down" class="size-4" />
        </span>
      </button>
    </div>
    """
  end

  @doc "Renders a scroll-to-top floating button."
  @spec scroll_to_top(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def scroll_to_top(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      id={"scroll-top-#{Map.get(assigns.node, "id", "default")}"}
      phx-hook="AlpineInit"
      x-data={Jason.encode!(%{"visible" => false})}
      x-on:scroll.window={"visible = window.scrollY > #{@props["threshold"] || 300}"}
      class={class_value(@classes, "custom")}
    >
      <button
        type="button"
        x-show="visible"
        x-transition
        x-on:click="window.scrollTo({top: 0, behavior: 'smooth'})"
        class={[
          "fixed bottom-6 right-6 z-50 btn btn-circle shadow-lg",
          scroll_top_style(@props["style"])
        ]}
        aria-label="Scroll to top"
      >
        <.icon name="hero-arrow-up" class="size-5" />
      </button>
    </div>
    """
  end

  @doc "Renders a cookie consent banner."
  @spec cookie_banner(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def cookie_banner(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      id={"cookie-#{Map.get(assigns.node, "id", "default")}"}
      phx-hook="AlpineInit"
      x-data={Jason.encode!(%{"accepted" => false})}
      x-init="accepted = localStorage.getItem('cookies_accepted') === 'true'"
      x-show="!accepted"
      x-transition
      class={[
        "fixed bottom-4 left-4 right-4 z-50 mx-auto max-w-2xl rounded-2xl border border-base-300 bg-base-100 p-6 shadow-xl",
        class_value(@classes, "custom")
      ]}
    >
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center">
        <div class="flex-1">
          <p class="font-semibold text-base-content">{@props["title"] || "We use cookies"}</p>
          <p class="mt-1 text-sm text-base-content/60">
            {@props["body"] ||
              "We use cookies to improve your experience. By continuing, you agree to our privacy policy."}
          </p>
          <a
            :if={@props["policy_label"] not in [nil, ""]}
            href={safe_href(@props["policy_href"] || "#")}
            class="mt-1 text-xs text-primary hover:underline"
          >
            {@props["policy_label"]}
          </a>
        </div>
        <div class="flex shrink-0 gap-2">
          <button
            type="button"
            class="btn btn-ghost btn-sm"
            x-on:click="accepted = true; localStorage.setItem('cookies_accepted', 'true')"
          >
            {@props["decline_label"] || "Decline"}
          </button>
          <button
            type="button"
            class="btn btn-primary btn-sm"
            x-on:click="accepted = true; localStorage.setItem('cookies_accepted', 'true')"
          >
            {@props["accept_label"] || "Accept all"}
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc "Renders a back navigation link."
  @spec back_link(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def back_link(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <a
      href={safe_href(@props["href"] || "#")}
      class={[
        "inline-flex items-center gap-1.5 text-sm font-medium text-base-content/60 hover:text-base-content transition-colors",
        class_value(@classes, "custom")
      ]}
    >
      <.icon name="hero-arrow-left" class="size-4" />
      {@props["label"] || "Back"}
    </a>
    """
  end

  @doc "Renders social share buttons."
  @spec share_buttons(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def share_buttons(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["flex flex-wrap items-center gap-2", class_value(@classes, "custom")]}>
      <span
        :if={@props["label"] not in [nil, ""]}
        class="text-sm font-medium text-base-content/60"
      >
        {@props["label"]}
      </span>
      <div
        id={"share-#{Map.get(assigns.node, "id", "default")}"}
        phx-hook="AlpineInit"
        x-data={Jason.encode!(%{"url" => ""})}
        x-init="url = encodeURIComponent(window.location.href)"
        class="flex flex-wrap gap-2"
      >
        <a
          :if={share_enabled?(@props, "twitter")}
          x-bind:href={"'https://twitter.com/intent/tweet?url=' + url + '&text=' + encodeURIComponent(#{Jason.encode!(@props["text"] || "")})"}
          target="_blank"
          rel="noopener noreferrer"
          class={["btn btn-sm gap-1", share_btn_style(@props["style"])]}
          aria-label="Share on Twitter/X"
        >
          <.icon name="hero-arrow-top-right-on-square" class="size-4" /> X
        </a>
        <a
          :if={share_enabled?(@props, "facebook")}
          x-bind:href="'https://www.facebook.com/sharer/sharer.php?u=' + url"
          target="_blank"
          rel="noopener noreferrer"
          class={["btn btn-sm gap-1", share_btn_style(@props["style"])]}
          aria-label="Share on Facebook"
        >
          <.icon name="hero-arrow-top-right-on-square" class="size-4" /> Facebook
        </a>
        <a
          :if={share_enabled?(@props, "linkedin")}
          x-bind:href="'https://www.linkedin.com/sharing/share-offsite/?url=' + url"
          target="_blank"
          rel="noopener noreferrer"
          class={["btn btn-sm gap-1", share_btn_style(@props["style"])]}
          aria-label="Share on LinkedIn"
        >
          <.icon name="hero-arrow-top-right-on-square" class="size-4" /> LinkedIn
        </a>
        <button
          :if={share_enabled?(@props, "copy")}
          type="button"
          x-on:click="navigator.clipboard.writeText(decodeURIComponent(url))"
          class={["btn btn-sm gap-1", share_btn_style(@props["style"])]}
          aria-label="Copy link"
        >
          <.icon name="hero-link" class="size-4" />
          {if @props["show_labels"] in [true, "true"], do: "Copy link", else: ""}
        </button>
      </div>
    </div>
    """
  end

  @doc "Renders an auto-generated table of contents from headings."
  @spec table_of_contents(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def table_of_contents(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <nav
      id={"toc-#{Map.get(assigns.node, "id", "default")}"}
      aria-label={@props["aria_label"] || "Table of contents"}
      class={[
        "rounded-xl border border-base-300 bg-base-100 p-4",
        toc_width(@props["width"]),
        class_value(@classes, "custom")
      ]}
    >
      <p
        :if={@props["title"] not in [nil, ""]}
        class="mb-3 text-xs font-semibold uppercase tracking-widest text-base-content/50"
      >
        {@props["title"]}
      </p>
      <ol class="space-y-1.5">
        <li :for={item <- toc_items(@props)}>
          <a
            href={safe_href(item["href"] || "#")}
            class={[
              "block text-sm hover:text-primary transition-colors",
              if(item["level"] in ["2", 2],
                do: "pl-0 text-base-content/80",
                else: "pl-4 text-base-content/60"
              )
            ]}
          >
            {item["label"] || "Section"}
          </a>
        </li>
      </ol>
    </nav>
    """
  end

  # ── Private helpers ───────────────────────────────────────────────────────────

  defp copy_btn_style("ghost"), do: "btn-ghost"
  defp copy_btn_style("outline"), do: "btn-outline"
  defp copy_btn_style(_), do: "btn-primary"

  defp read_more_preview_height("3"), do: 72
  defp read_more_preview_height("4"), do: 96
  defp read_more_preview_height("6"), do: 144
  defp read_more_preview_height(_), do: 120

  defp scroll_top_style("primary"), do: "btn-primary"
  defp scroll_top_style("neutral"), do: "btn-neutral"
  defp scroll_top_style("ghost"), do: "btn-ghost border border-base-300"
  defp scroll_top_style(_), do: "btn-primary"

  defp share_enabled?(%{"platforms" => platforms}, key) when is_list(platforms),
    do: key in platforms

  defp share_enabled?(_, "twitter"), do: true
  defp share_enabled?(_, "linkedin"), do: true
  defp share_enabled?(_, "copy"), do: true
  defp share_enabled?(_, _), do: false

  defp share_btn_style("ghost"), do: "btn-ghost"
  defp share_btn_style("outline"), do: "btn-outline"
  defp share_btn_style(_), do: "btn-ghost border border-base-300"

  defp toc_items(%{"items" => items}) when is_list(items) and items != [], do: items

  defp toc_items(_) do
    [
      %{"href" => "#introduction", "label" => "Introduction", "level" => "2"},
      %{"href" => "#getting-started", "label" => "Getting Started", "level" => "2"},
      %{"href" => "#installation", "label" => "Installation", "level" => "3"},
      %{"href" => "#configuration", "label" => "Configuration", "level" => "3"},
      %{"href" => "#conclusion", "label" => "Conclusion", "level" => "2"}
    ]
  end

  defp toc_width("sm"), do: "max-w-xs"
  defp toc_width("full"), do: "w-full"
  defp toc_width(_), do: "max-w-sm"

  defp safe_href(href) when is_binary(href) do
    allowed = ["#", "/", "http://", "https://", "mailto:", "tel:"]
    if Enum.any?(allowed, &String.starts_with?(href, &1)), do: href, else: "#"
  end

  defp safe_href(_), do: "#"

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""
end
