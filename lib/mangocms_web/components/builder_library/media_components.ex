defmodule MangoCMSWeb.BuilderLibrary.MediaComponents do
  @moduledoc """
  Pure Phoenix renderers for builder media components.
  """

  use MangoCMSWeb, :html

  @doc "Renders an image with optional caption."
  @spec image(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def image(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <figure class={["block", class_value(@classes, "custom")]}>
      <img
        src={@props["src"] || "/images/no-image-placeholder.webp"}
        alt={@props["alt"] || ""}
        class={[
          "w-full",
          image_aspect(@props["aspect_ratio"]),
          image_object_fit(@props["object_fit"]),
          image_rounded(@props["rounded"])
        ]}
      />
      <figcaption
        :if={@props["caption"] not in [nil, ""]}
        class="mt-2 text-center text-sm text-base-content/60"
      >
        {@props["caption"]}
      </figcaption>
    </figure>
    """
  end

  @doc "Renders a video player or YouTube/Vimeo embed."
  @spec video(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def video(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "w-full overflow-hidden",
      video_aspect(@props["aspect_ratio"]),
      image_rounded(@props["rounded"]),
      class_value(@classes, "custom")
    ]}>
      <%= case @props["embed_type"] do %>
        <% "youtube" -> %>
          <iframe
            src={youtube_embed_url(@props["src"])}
            class="h-full w-full"
            frameborder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowfullscreen
            title={@props["title"] || "YouTube video"}
          >
          </iframe>
        <% "vimeo" -> %>
          <iframe
            src={vimeo_embed_url(@props["src"])}
            class="h-full w-full"
            frameborder="0"
            allow="autoplay; fullscreen; picture-in-picture"
            allowfullscreen
            title={@props["title"] || "Vimeo video"}
          >
          </iframe>
        <% _ -> %>
          <video
            src={@props["src"] || ""}
            class="h-full w-full"
            controls={video_bool(@props["controls"])}
            autoplay={video_bool(@props["autoplay"])}
            loop={video_bool(@props["loop"])}
            muted={video_bool(@props["autoplay"])}
          >
            Your browser does not support video playback.
          </video>
      <% end %>
    </div>
    """
  end

  @doc "Renders an audio player."
  @spec audio(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def audio(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["w-full", class_value(@classes, "custom")]}>
      <audio
        src={@props["src"] || ""}
        class="w-full"
        controls={video_bool(@props["controls"])}
        autoplay={video_bool(@props["autoplay"])}
        loop={video_bool(@props["loop"])}
      >
        Your browser does not support audio playback.
      </audio>
    </div>
    """
  end

  @doc "Renders a responsive image gallery grid with Alpine lightbox."
  @spec gallery(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def gallery(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      id={"gallery-#{Map.get(assigns.node, "id", "default")}"}
      phx-hook="AlpineInit"
      x-data={Jason.encode!(%{"open" => false, "active" => 0})}
      x-on:keydown.escape.window="open = false"
      class={class_value(@classes, "custom")}
    >
      <div class={[
        "grid",
        gallery_columns(@props["columns"]),
        gallery_gap(@props["gap"])
      ]}>
        <button
          :for={{img, idx} <- Enum.with_index(gallery_images(@props))}
          type="button"
          x-on:click={"active = #{idx}; open = true"}
          class={[
            "overflow-hidden focus:outline-none focus:ring-2 focus:ring-primary",
            image_rounded(@props["rounded"])
          ]}
        >
          <img
            src={img["src"] || "/images/no-image-placeholder.webp"}
            alt={img["alt"] || ""}
            class="h-full w-full object-cover transition hover:scale-105"
            loading="lazy"
          />
        </button>
      </div>

      <%!-- Lightbox --%>
      <div
        x-show="open"
        x-transition
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4"
        role="dialog"
        aria-modal="true"
      >
        <button
          type="button"
          class="absolute right-4 top-4 btn btn-circle btn-sm btn-ghost text-white"
          x-on:click="open = false"
          aria-label="Close lightbox"
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>
        <img
          :for={{img, idx} <- Enum.with_index(gallery_images(@props))}
          x-show={"active === #{idx}"}
          src={img["src"] || "/images/no-image-placeholder.webp"}
          alt={img["alt"] || ""}
          class="max-h-[90vh] max-w-full rounded-lg object-contain shadow-2xl"
        />
      </div>
    </div>
    """
  end

  @doc "Renders an iframe embed."
  @spec embed(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def embed(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "w-full overflow-hidden rounded-lg",
      video_aspect(@props["aspect_ratio"]),
      class_value(@classes, "custom")
    ]}>
      <iframe
        :if={safe_embed_url?(@props["url"])}
        src={@props["url"]}
        class="h-full w-full border-0"
        title={@props["title"] || "Embedded content"}
        loading="lazy"
        allowfullscreen
      >
      </iframe>
      <div
        :if={!safe_embed_url?(@props["url"])}
        class="flex h-full w-full items-center justify-center bg-base-200 text-base-content/40 text-sm"
      >
        Enter a valid URL to embed
      </div>
    </div>
    """
  end

  @doc "Renders an icon with optional label."
  @spec icon_block(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def icon_block(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "flex flex-col",
      icon_block_align(@props["align"]),
      class_value(@classes, "custom")
    ]}>
      <.icon
        name={@props["icon"] || "hero-star"}
        class={[icon_block_size(@props["size"]), icon_block_color(@props["color"])]}
      />
      <span
        :if={@props["label"] not in [nil, ""]}
        class={["mt-2 font-medium", icon_label_size(@props["label_size"])]}
      >
        {@props["label"]}
      </span>
    </div>
    """
  end

  # ── Private helpers ───────────────────────────────────────────────────────────

  defp image_aspect("square"), do: "aspect-square"
  defp image_aspect("video"), do: "aspect-video"
  defp image_aspect("portrait"), do: "aspect-[3/4]"
  defp image_aspect("wide"), do: "aspect-[21/9]"
  defp image_aspect(_), do: ""

  defp image_object_fit("contain"), do: "object-contain"
  defp image_object_fit("fill"), do: "object-fill"
  defp image_object_fit("none"), do: "object-none"
  defp image_object_fit(_), do: "object-cover"

  defp image_rounded("sm"), do: "rounded-lg"
  defp image_rounded("md"), do: "rounded-xl"
  defp image_rounded("lg"), do: "rounded-2xl"
  defp image_rounded("full"), do: "rounded-full"
  defp image_rounded(_), do: "rounded-lg"

  defp video_aspect("square"), do: "aspect-square"
  defp video_aspect("portrait"), do: "aspect-[9/16]"
  defp video_aspect("wide"), do: "aspect-[21/9]"
  defp video_aspect(_), do: "aspect-video"

  defp video_bool(true), do: true
  defp video_bool("true"), do: true
  defp video_bool(_), do: false

  defp youtube_embed_url(url) when is_binary(url) do
    id =
      cond do
        String.contains?(url, "youtu.be/") ->
          url |> String.split("youtu.be/") |> List.last() |> String.split("?") |> hd()

        String.contains?(url, "v=") ->
          url |> URI.parse() |> Map.get(:query, "") |> URI.decode_query() |> Map.get("v", "")

        true ->
          url
      end

    "https://www.youtube.com/embed/#{id}"
  end

  defp youtube_embed_url(_), do: ""

  defp vimeo_embed_url(url) when is_binary(url) do
    id = url |> String.split("/") |> List.last() |> String.split("?") |> hd()
    "https://player.vimeo.com/video/#{id}"
  end

  defp vimeo_embed_url(_), do: ""

  defp gallery_images(%{"images" => images}) when is_list(images) and images != [], do: images

  defp gallery_images(_props) do
    [
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Gallery image 1"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Gallery image 2"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Gallery image 3"}
    ]
  end

  defp gallery_columns("2"), do: "grid-cols-2"
  defp gallery_columns("3"), do: "grid-cols-2 sm:grid-cols-3"
  defp gallery_columns("4"), do: "grid-cols-2 sm:grid-cols-4"
  defp gallery_columns(_), do: "grid-cols-2 sm:grid-cols-3"

  defp gallery_gap("sm"), do: "gap-1"
  defp gallery_gap("lg"), do: "gap-4"
  defp gallery_gap("xl"), do: "gap-6"
  defp gallery_gap(_), do: "gap-2"

  @safe_schemes ["http://", "https://"]

  defp safe_embed_url?(url) when is_binary(url) do
    Enum.any?(@safe_schemes, &String.starts_with?(url, &1))
  end

  defp safe_embed_url?(_), do: false

  defp icon_block_align("center"), do: "items-center text-center"
  defp icon_block_align("end"), do: "items-end text-right"
  defp icon_block_align(_), do: "items-start"

  defp icon_block_size("xs"), do: "size-5"
  defp icon_block_size("sm"), do: "size-8"
  defp icon_block_size("lg"), do: "size-14"
  defp icon_block_size("xl"), do: "size-20"
  defp icon_block_size(_), do: "size-10"

  defp icon_block_color("primary"), do: "text-primary"
  defp icon_block_color("secondary"), do: "text-secondary"
  defp icon_block_color("accent"), do: "text-accent"
  defp icon_block_color("success"), do: "text-success"
  defp icon_block_color("warning"), do: "text-warning"
  defp icon_block_color("error"), do: "text-error"
  defp icon_block_color(_), do: "text-base-content"

  defp icon_label_size("xs"), do: "text-xs"
  defp icon_label_size("sm"), do: "text-sm"
  defp icon_label_size("lg"), do: "text-lg"
  defp icon_label_size(_), do: "text-sm"

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""
end
