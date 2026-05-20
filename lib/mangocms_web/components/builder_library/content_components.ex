defmodule MangoCMSWeb.BuilderLibrary.ContentComponents do
  @moduledoc """
  Pure Phoenix renderers for builder content/marketing components.
  """

  use MangoCMSWeb, :html

  @doc "Renders a feature card with icon, heading, and body."
  @spec feature_card(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def feature_card(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "flex flex-col",
      feature_card_variant_class(Map.get(assigns.node, "variant", "border")),
      class_value(@classes, "custom")
    ]}>
      <div
        :if={@props["icon"] not in [nil, ""]}
        class={["mb-4", feature_icon_bg(@props["icon_color"])]}
      >
        <.icon
          name={@props["icon"] || "hero-star"}
          class={["size-8", feature_icon_color(@props["icon_color"])]}
        />
      </div>
      <h3 class="mb-2 text-lg font-semibold text-base-content">
        {@props["title"] || "Feature Title"}
      </h3>
      <p class="text-base-content/70 leading-relaxed">
        {@props["body"] || "Describe this feature here."}
      </p>
      <a
        :if={@props["link_label"] not in [nil, ""] && @props["link_href"] not in [nil, ""]}
        href={safe_href(@props["link_href"])}
        class="mt-4 inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
      >
        {@props["link_label"]} <.icon name="hero-arrow-right" class="size-3" />
      </a>
    </div>
    """
  end

  @doc "Renders a grid of feature items."
  @spec feature_grid(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def feature_grid(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "grid",
      feature_grid_cols(@props["columns"]),
      feature_grid_gap(@props["gap"]),
      class_value(@classes, "custom")
    ]}>
      <div
        :for={item <- feature_grid_items(@props)}
        class={["flex flex-col", feature_card_variant_class(@props["card_variant"] || "border")]}
      >
        <div :if={item["icon"] not in [nil, ""]} class="mb-3">
          <.icon
            name={item["icon"] || "hero-star"}
            class={["size-7", feature_icon_color(@props["icon_color"])]}
          />
        </div>
        <h3 class="mb-1 font-semibold text-base-content">{item["title"] || "Feature"}</h3>
        <p class="text-sm text-base-content/70">{item["body"] || ""}</p>
      </div>
    </div>
    """
  end

  @doc "Renders a call-to-action section."
  @spec cta_section(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def cta_section(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "rounded-2xl p-8 md:p-12",
      cta_bg(@props["bg"]),
      cta_align(Map.get(assigns.node, "variant", "centered")),
      class_value(@classes, "custom")
    ]}>
      <p
        :if={@props["eyebrow"] not in [nil, ""]}
        class="mb-2 text-xs font-semibold uppercase tracking-widest text-primary"
      >
        {@props["eyebrow"]}
      </p>
      <h2 class="text-3xl font-bold text-base-content md:text-4xl">
        {@props["title"] || "Ready to get started?"}
      </h2>
      <p
        :if={@props["body"] not in [nil, ""]}
        class="mt-4 max-w-xl text-base-content/70 leading-relaxed"
      >
        {@props["body"]}
      </p>
      <div class="mt-8 flex flex-wrap gap-3">
        <a
          :if={@props["primary_label"] not in [nil, ""]}
          href={safe_href(@props["primary_href"] || "#")}
          class="btn btn-primary"
        >
          {@props["primary_label"]}
        </a>
        <a
          :if={@props["secondary_label"] not in [nil, ""]}
          href={safe_href(@props["secondary_href"] || "#")}
          class="btn btn-ghost"
        >
          {@props["secondary_label"]}
        </a>
      </div>
    </div>
    """
  end

  @doc "Renders a testimonial quote."
  @spec testimonial(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def testimonial(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <figure class={[
      testimonial_variant_class(Map.get(assigns.node, "variant", "card")),
      class_value(@classes, "custom")
    ]}>
      <.icon name="hero-chat-bubble-left-right" class="mb-4 size-6 text-primary/60" />
      <blockquote class="text-base-content/80 italic leading-relaxed">
        <p>{@props["quote"] || "This product changed everything for our team."}</p>
      </blockquote>
      <figcaption class="mt-6 flex items-center gap-3">
        <div
          :if={@props["avatar"] not in [nil, ""]}
          class="size-10 overflow-hidden rounded-full bg-base-300"
        >
          <img src={@props["avatar"]} alt={@props["name"] || ""} class="h-full w-full object-cover" />
        </div>
        <div
          :if={@props["avatar"] in [nil, ""]}
          class="flex size-10 items-center justify-center rounded-full bg-primary/10 text-sm font-semibold text-primary"
        >
          {avatar_initials(@props["name"])}
        </div>
        <div>
          <p class="font-semibold text-base-content">{@props["name"] || "Jane Doe"}</p>
          <p
            :if={@props["role"] not in [nil, ""]}
            class="text-xs text-base-content/50"
          >
            {@props["role"]}
          </p>
        </div>
      </figcaption>
    </figure>
    """
  end

  @doc "Renders a grid of testimonials."
  @spec testimonial_grid(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def testimonial_grid(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "grid",
      testimonial_grid_cols(@props["columns"]),
      "gap-6",
      class_value(@classes, "custom")
    ]}>
      <figure
        :for={item <- testimonial_items(@props)}
        class="rounded-2xl border border-base-300 bg-base-100 p-6"
      >
        <.icon name="hero-chat-bubble-left-right" class="mb-3 size-5 text-primary/60" />
        <blockquote class="text-sm text-base-content/80 italic leading-relaxed">
          <p>{item["quote"] || "Great product!"}</p>
        </blockquote>
        <figcaption class="mt-4 flex items-center gap-2">
          <div class="flex size-8 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
            {avatar_initials(item["name"])}
          </div>
          <div>
            <p class="text-sm font-semibold text-base-content">{item["name"] || "Author"}</p>
            <p :if={item["role"] not in [nil, ""]} class="text-xs text-base-content/40">
              {item["role"]}
            </p>
          </div>
        </figcaption>
      </figure>
    </div>
    """
  end

  @doc "Renders a single pricing card."
  @spec pricing_card(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def pricing_card(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    highlighted = assigns.props["highlighted"] in [true, "true"]

    assigns = assign(assigns, :highlighted, highlighted)

    ~H"""
    <div class={[
      "relative flex flex-col rounded-2xl p-8",
      if(@highlighted,
        do: "bg-primary text-primary-content shadow-xl ring-2 ring-primary",
        else: "border border-base-300 bg-base-100"
      ),
      class_value(@classes, "custom")
    ]}>
      <div
        :if={@props["badge"] not in [nil, ""]}
        class="absolute -top-3 left-1/2 -translate-x-1/2"
      >
        <span class="badge badge-secondary badge-lg">{@props["badge"]}</span>
      </div>
      <h3 class={[
        "text-xl font-bold",
        if(@highlighted, do: "text-primary-content", else: "text-base-content")
      ]}>
        {@props["plan"] || "Starter"}
      </h3>
      <p class={[
        "mt-1 text-sm",
        if(@highlighted, do: "text-primary-content/70", else: "text-base-content/50")
      ]}>
        {@props["description"] || ""}
      </p>
      <div class="my-6 flex items-end gap-1">
        <span class={[
          "text-5xl font-black",
          if(@highlighted, do: "text-primary-content", else: "text-base-content")
        ]}>
          {@props["price"] || "$0"}
        </span>
        <span class={[
          "mb-1 text-sm",
          if(@highlighted, do: "text-primary-content/60", else: "text-base-content/40")
        ]}>
          /{@props["period"] || "mo"}
        </span>
      </div>
      <ul class="mb-8 flex-1 space-y-3">
        <li
          :for={feat <- pricing_features(@props)}
          class={[
            "flex items-center gap-2 text-sm",
            if(@highlighted, do: "text-primary-content/80", else: "text-base-content/70")
          ]}
        >
          <.icon name="hero-check" class="size-4 shrink-0 text-success" />
          {feat}
        </li>
      </ul>
      <a
        href={safe_href(@props["cta_href"] || "#")}
        class={[
          "btn w-full",
          if(@highlighted, do: "btn-neutral", else: "btn-primary")
        ]}
      >
        {@props["cta_label"] || "Get started"}
      </a>
    </div>
    """
  end

  @doc "Renders a side-by-side pricing table."
  @spec pricing_table(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def pricing_table(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "grid gap-6",
      pricing_table_cols(pricing_tiers(@props)),
      class_value(@classes, "custom")
    ]}>
      <div
        :for={tier <- pricing_tiers(@props)}
        class={[
          "relative flex flex-col rounded-2xl p-8",
          if(tier["highlighted"] in [true, "true"],
            do: "bg-primary text-primary-content shadow-xl ring-2 ring-primary",
            else: "border border-base-300 bg-base-100"
          )
        ]}
      >
        <div :if={tier["badge"] not in [nil, ""]} class="absolute -top-3 left-1/2 -translate-x-1/2">
          <span class="badge badge-secondary badge-lg">{tier["badge"]}</span>
        </div>
        <h3 class="text-xl font-bold">{tier["plan"] || "Plan"}</h3>
        <div class="my-4 flex items-end gap-1">
          <span class="text-4xl font-black">{tier["price"] || "$0"}</span>
          <span class="mb-1 text-sm opacity-60">/{tier["period"] || "mo"}</span>
        </div>
        <ul class="mb-6 flex-1 space-y-2">
          <li :for={feat <- tier_features(tier)} class="flex items-center gap-2 text-sm">
            <.icon name="hero-check" class="size-4 shrink-0 text-success" /> {feat}
          </li>
        </ul>
        <a href={safe_href(tier["cta_href"] || "#")} class="btn btn-primary w-full">
          {tier["cta_label"] || "Get started"}
        </a>
      </div>
    </div>
    """
  end

  @doc "Renders a team member card."
  @spec team_member(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def team_member(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "flex flex-col items-center text-center",
      class_value(@classes, "custom")
    ]}>
      <div class="mb-4 size-24 overflow-hidden rounded-full bg-base-300">
        <img
          :if={@props["photo"] not in [nil, ""]}
          src={@props["photo"]}
          alt={@props["name"] || "Team member"}
          class="h-full w-full object-cover"
        />
        <div
          :if={@props["photo"] in [nil, ""]}
          class="flex h-full w-full items-center justify-center text-2xl font-bold text-base-content/40"
        >
          {avatar_initials(@props["name"])}
        </div>
      </div>
      <h3 class="text-lg font-semibold text-base-content">{@props["name"] || "Team Member"}</h3>
      <p :if={@props["role"] not in [nil, ""]} class="text-sm text-primary font-medium mt-0.5">
        {@props["role"]}
      </p>
      <p
        :if={@props["bio"] not in [nil, ""]}
        class="mt-3 text-sm text-base-content/60 leading-relaxed max-w-xs"
      >
        {@props["bio"]}
      </p>
      <div :if={team_socials(@props) != []} class="mt-4 flex gap-3">
        <a
          :for={social <- team_socials(@props)}
          href={safe_href(social["href"] || "#")}
          class="text-base-content/40 hover:text-primary transition-colors"
          aria-label={social["label"] || "Social link"}
        >
          <.icon name={social["icon"] || "hero-link"} class="size-4" />
        </a>
      </div>
    </div>
    """
  end

  @doc "Renders a grid of team members."
  @spec team_grid(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def team_grid(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "grid",
      team_grid_cols(@props["columns"]),
      "gap-8",
      class_value(@classes, "custom")
    ]}>
      <div
        :for={member <- team_members(@props)}
        class="flex flex-col items-center text-center"
      >
        <div class="mb-3 size-20 overflow-hidden rounded-full bg-base-300">
          <img
            :if={member["photo"] not in [nil, ""]}
            src={member["photo"]}
            alt={member["name"] || ""}
            class="h-full w-full object-cover"
          />
          <div
            :if={member["photo"] in [nil, ""]}
            class="flex h-full w-full items-center justify-center text-xl font-bold text-base-content/40"
          >
            {avatar_initials(member["name"])}
          </div>
        </div>
        <p class="font-semibold text-base-content">{member["name"] || "Name"}</p>
        <p :if={member["role"] not in [nil, ""]} class="text-xs text-primary mt-0.5">
          {member["role"]}
        </p>
      </div>
    </div>
    """
  end

  @doc "Renders an FAQ accordion section."
  @spec faq_section(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def faq_section(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      id={"faq-#{Map.get(assigns.node, "id", "default")}"}
      phx-hook="AlpineInit"
      x-data={Jason.encode!(%{"open" => nil})}
      class={["space-y-2", class_value(@classes, "custom")]}
    >
      <div
        :for={{item, idx} <- Enum.with_index(faq_items(@props))}
        class="collapse collapse-arrow border border-base-300 bg-base-100 rounded-xl"
        x-bind:class={"open === #{idx} && 'collapse-open'"}
      >
        <div
          class="collapse-title font-medium cursor-pointer select-none"
          x-on:click={"open = open === #{idx} ? null : #{idx}"}
        >
          {item["question"] || "Frequently asked question?"}
        </div>
        <div class="collapse-content">
          <p class="text-base-content/70 leading-relaxed pt-1">
            {item["answer"] || "Answer goes here."}
          </p>
        </div>
      </div>
    </div>
    """
  end

  @doc "Renders a dismissible banner strip."
  @spec banner(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def banner(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      id={"banner-#{Map.get(assigns.node, "id", "default")}"}
      phx-hook="AlpineInit"
      x-data={Jason.encode!(%{"dismissed" => false})}
      x-show="!dismissed"
      class={[
        "relative flex items-center justify-between gap-4 px-4 py-3 text-sm",
        banner_bg(@props["style"]),
        class_value(@classes, "custom")
      ]}
    >
      <div class="flex items-center gap-2 flex-1 justify-center">
        <.icon
          :if={@props["icon"] not in [nil, ""]}
          name={@props["icon"]}
          class="size-4 shrink-0"
        />
        <span>{@props["text"] || "Announcement text goes here."}</span>
        <a
          :if={@props["link_label"] not in [nil, ""]}
          href={safe_href(@props["link_href"] || "#")}
          class="font-semibold underline hover:no-underline"
        >
          {@props["link_label"]}
        </a>
      </div>
      <button
        :if={@props["dismissible"] in [true, "true"]}
        type="button"
        class="btn btn-ghost btn-xs btn-circle shrink-0"
        x-on:click="dismissed = true"
        aria-label="Dismiss"
      >
        <.icon name="hero-x-mark" class="size-4" />
      </button>
    </div>
    """
  end

  @doc "Renders a logo grid / partner logos."
  @spec logo_grid(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def logo_grid(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    grayscale = assigns.props["grayscale"] in [true, "true"]
    assigns = assign(assigns, :grayscale, grayscale)

    ~H"""
    <div class={["space-y-6", class_value(@classes, "custom")]}>
      <p
        :if={@props["label"] not in [nil, ""]}
        class="text-center text-xs font-semibold uppercase tracking-widest text-base-content/40"
      >
        {@props["label"]}
      </p>
      <div class={[
        "flex flex-wrap items-center justify-center",
        logo_grid_gap(@props["gap"])
      ]}>
        <div
          :for={logo <- logo_items(@props)}
          class={[
            "flex items-center justify-center transition-opacity hover:opacity-100",
            if(@grayscale, do: "grayscale opacity-50", else: "")
          ]}
        >
          <img
            src={logo["src"] || "/images/no-image-placeholder.webp"}
            alt={logo["alt"] || "Partner logo"}
            class="h-8 w-auto object-contain"
          />
        </div>
      </div>
    </div>
    """
  end

  @doc "Renders a numbered steps / how-it-works section."
  @spec steps_section(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def steps_section(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "grid",
      steps_cols(steps_items(@props)),
      "gap-8",
      class_value(@classes, "custom")
    ]}>
      <div
        :for={{step, idx} <- Enum.with_index(steps_items(@props))}
        class="flex flex-col items-center text-center"
      >
        <div class={[
          "mb-4 flex size-12 items-center justify-center rounded-full text-lg font-bold",
          steps_number_style(@props["style"])
        ]}>
          {idx + 1}
        </div>
        <h3 class="mb-2 font-semibold text-base-content">{step["title"] || "Step"}</h3>
        <p class="text-sm text-base-content/60 leading-relaxed">{step["body"] || ""}</p>
      </div>
    </div>
    """
  end

  @doc "Renders an empty state / zero-data placeholder."
  @spec empty_state(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def empty_state(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={[
      "flex flex-col items-center justify-center py-16 text-center",
      class_value(@classes, "custom")
    ]}>
      <img
        :if={@props["image"] not in [nil, ""]}
        src={@props["image"]}
        alt=""
        class="mb-6 h-32 w-auto opacity-60"
      />
      <.icon
        :if={@props["image"] in [nil, ""] && @props["icon"] not in [nil, ""]}
        name={@props["icon"]}
        class="mb-4 size-12 text-base-content/20"
      />
      <h3 class="text-lg font-semibold text-base-content">
        {@props["title"] || "Nothing here yet"}
      </h3>
      <p
        :if={@props["body"] not in [nil, ""]}
        class="mt-2 max-w-sm text-sm text-base-content/50"
      >
        {@props["body"]}
      </p>
      <a
        :if={@props["cta_label"] not in [nil, ""]}
        href={safe_href(@props["cta_href"] || "#")}
        class="btn btn-primary mt-6"
      >
        {@props["cta_label"]}
      </a>
    </div>
    """
  end

  @doc "Renders a sticky notification bar."
  @spec notification_bar(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def notification_bar(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div
      id={"notif-bar-#{Map.get(assigns.node, "id", "default")}"}
      phx-hook="AlpineInit"
      x-data={Jason.encode!(%{"dismissed" => false})}
      x-show="!dismissed"
      class={[
        "fixed bottom-0 left-0 right-0 z-40 flex items-center justify-between gap-4 px-6 py-4 shadow-lg",
        notif_bar_bg(@props["style"]),
        class_value(@classes, "custom")
      ]}
    >
      <div class="flex items-center gap-3 flex-1">
        <.icon
          :if={@props["icon"] not in [nil, ""]}
          name={@props["icon"]}
          class="size-5 shrink-0"
        />
        <p class="text-sm">{@props["text"] || "Notification message."}</p>
        <a
          :if={@props["link_label"] not in [nil, ""]}
          href={safe_href(@props["link_href"] || "#")}
          class="font-semibold underline hover:no-underline text-sm"
        >
          {@props["link_label"]}
        </a>
      </div>
      <div class="flex items-center gap-2 shrink-0">
        <a
          :if={@props["cta_label"] not in [nil, ""]}
          href={safe_href(@props["cta_href"] || "#")}
          class="btn btn-sm btn-primary"
        >
          {@props["cta_label"]}
        </a>
        <button
          type="button"
          class="btn btn-ghost btn-sm btn-circle"
          x-on:click="dismissed = true"
          aria-label="Dismiss"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>
    </div>
    """
  end

  # ── Private helpers ───────────────────────────────────────────────────────────

  defp feature_card_variant_class("bordered"),
    do: "rounded-2xl border border-base-300 bg-base-100 p-6"

  defp feature_card_variant_class("filled"),
    do: "rounded-2xl bg-base-200 p-6"

  defp feature_card_variant_class("ghost"), do: "p-2"
  defp feature_card_variant_class(_), do: "rounded-2xl border border-base-300 bg-base-100 p-6"

  defp feature_icon_bg("primary"), do: "inline-flex rounded-xl bg-primary/10 p-3"
  defp feature_icon_bg("secondary"), do: "inline-flex rounded-xl bg-secondary/10 p-3"
  defp feature_icon_bg("accent"), do: "inline-flex rounded-xl bg-accent/10 p-3"
  defp feature_icon_bg(_), do: "inline-flex rounded-xl bg-base-200 p-3"

  defp feature_icon_color("primary"), do: "text-primary"
  defp feature_icon_color("secondary"), do: "text-secondary"
  defp feature_icon_color("accent"), do: "text-accent"
  defp feature_icon_color("success"), do: "text-success"
  defp feature_icon_color(_), do: "text-base-content"

  defp feature_grid_cols("2"), do: "grid-cols-1 sm:grid-cols-2"
  defp feature_grid_cols("4"), do: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4"
  defp feature_grid_cols(_), do: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"

  defp feature_grid_gap("sm"), do: "gap-4"
  defp feature_grid_gap("lg"), do: "gap-8"
  defp feature_grid_gap(_), do: "gap-6"

  defp feature_grid_items(%{"items" => items}) when is_list(items) and items != [], do: items

  defp feature_grid_items(_) do
    [
      %{"icon" => "hero-bolt", "title" => "Fast", "body" => "Blazing speed."},
      %{"icon" => "hero-shield-check", "title" => "Secure", "body" => "Enterprise grade."},
      %{"icon" => "hero-chart-bar", "title" => "Scalable", "body" => "Grows with you."}
    ]
  end

  defp cta_bg("primary"), do: "bg-primary text-primary-content"
  defp cta_bg("neutral"), do: "bg-neutral text-neutral-content"
  defp cta_bg("gradient"), do: "bg-gradient-to-r from-primary to-secondary text-primary-content"
  defp cta_bg(_), do: "bg-base-200"

  defp cta_align("left_aligned"), do: "text-left"
  defp cta_align(_), do: "text-center flex flex-col items-center"

  defp testimonial_variant_class("minimal"), do: "py-6"
  defp testimonial_variant_class("large"), do: "rounded-2xl bg-base-200 p-10"
  defp testimonial_variant_class(_), do: "rounded-2xl border border-base-300 bg-base-100 p-8"

  defp testimonial_grid_cols("2"), do: "grid-cols-1 sm:grid-cols-2"
  defp testimonial_grid_cols("3"), do: "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
  defp testimonial_grid_cols(_), do: "grid-cols-1 sm:grid-cols-2"

  defp testimonial_items(%{"items" => items}) when is_list(items) and items != [], do: items

  defp testimonial_items(_) do
    [
      %{"quote" => "Incredible product!", "name" => "Alice B.", "role" => "CEO"},
      %{"quote" => "Changed everything.", "name" => "Bob C.", "role" => "CTO"}
    ]
  end

  defp pricing_features(%{"features" => f}) when is_list(f) and f != [], do: f
  defp pricing_features(_), do: ["Feature one", "Feature two", "Feature three"]

  defp pricing_tiers(%{"tiers" => t}) when is_list(t) and t != [], do: t

  defp pricing_tiers(_) do
    [
      %{
        "plan" => "Starter",
        "price" => "$9",
        "period" => "mo",
        "cta_label" => "Start free",
        "cta_href" => "#",
        "features" => ["5 projects", "10 GB storage"]
      },
      %{
        "plan" => "Pro",
        "price" => "$29",
        "period" => "mo",
        "cta_label" => "Get Pro",
        "cta_href" => "#",
        "highlighted" => true,
        "badge" => "Popular",
        "features" => ["Unlimited projects", "100 GB storage", "Priority support"]
      }
    ]
  end

  defp pricing_table_cols(tiers) when length(tiers) >= 3, do: "grid-cols-1 md:grid-cols-3"
  defp pricing_table_cols(_), do: "grid-cols-1 md:grid-cols-2"

  defp tier_features(%{"features" => f}) when is_list(f), do: f
  defp tier_features(_), do: []

  defp team_socials(%{"socials" => s}) when is_list(s) and s != [], do: s
  defp team_socials(_), do: []

  defp team_members(%{"members" => m}) when is_list(m) and m != [], do: m

  defp team_members(_) do
    [
      %{"name" => "Alice Smith", "role" => "CEO", "photo" => ""},
      %{"name" => "Bob Jones", "role" => "CTO", "photo" => ""},
      %{"name" => "Carol Lee", "role" => "Designer", "photo" => ""}
    ]
  end

  defp team_grid_cols("2"), do: "grid-cols-2"
  defp team_grid_cols("4"), do: "grid-cols-2 sm:grid-cols-4"
  defp team_grid_cols(_), do: "grid-cols-2 sm:grid-cols-3"

  defp faq_items(%{"items" => items}) when is_list(items) and items != [], do: items

  defp faq_items(_) do
    [
      %{
        "question" => "What is your refund policy?",
        "answer" => "We offer a 30-day money-back guarantee."
      },
      %{"question" => "Do you offer support?", "answer" => "Yes, 24/7 via chat and email."},
      %{"question" => "Can I cancel anytime?", "answer" => "Absolutely, no questions asked."}
    ]
  end

  defp banner_bg("info"), do: "bg-info text-info-content"
  defp banner_bg("success"), do: "bg-success text-success-content"
  defp banner_bg("warning"), do: "bg-warning text-warning-content"
  defp banner_bg("error"), do: "bg-error text-error-content"
  defp banner_bg(_), do: "bg-primary text-primary-content"

  defp notif_bar_bg("neutral"), do: "bg-neutral text-neutral-content"
  defp notif_bar_bg("info"), do: "bg-info text-info-content"
  defp notif_bar_bg("success"), do: "bg-success text-success-content"
  defp notif_bar_bg("warning"), do: "bg-warning text-warning-content"
  defp notif_bar_bg("error"), do: "bg-error text-error-content"
  defp notif_bar_bg(_), do: "bg-base-200 text-base-content"

  defp logo_items(%{"logos" => l}) when is_list(l) and l != [], do: l

  defp logo_items(_) do
    [
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Logo 1"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Logo 2"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Logo 3"},
      %{"src" => "/images/no-image-placeholder.webp", "alt" => "Logo 4"}
    ]
  end

  defp logo_grid_gap("sm"), do: "gap-4"
  defp logo_grid_gap("lg"), do: "gap-10"
  defp logo_grid_gap(_), do: "gap-8"

  defp steps_items(%{"steps" => s}) when is_list(s) and s != [], do: s

  defp steps_items(_) do
    [
      %{"title" => "Sign up", "body" => "Create your account in seconds."},
      %{"title" => "Connect", "body" => "Link your tools and data sources."},
      %{"title" => "Launch", "body" => "Go live and start growing."}
    ]
  end

  defp steps_cols(items) when length(items) == 2, do: "grid-cols-1 sm:grid-cols-2"
  defp steps_cols(items) when length(items) >= 4, do: "grid-cols-2 sm:grid-cols-4"
  defp steps_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  defp steps_number_style("outline"),
    do: "border-2 border-primary text-primary bg-transparent"

  defp steps_number_style("ghost"), do: "bg-base-200 text-base-content"
  defp steps_number_style(_), do: "bg-primary text-primary-content"

  defp avatar_initials(nil), do: "?"
  defp avatar_initials(""), do: "?"

  defp avatar_initials(name) do
    name
    |> String.split()
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp safe_href(href) when is_binary(href) do
    allowed = ["#", "/", "http://", "https://", "mailto:", "tel:"]
    if Enum.any?(allowed, &String.starts_with?(href, &1)), do: href, else: "#"
  end

  defp safe_href(_), do: "#"

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""
end
