defmodule MangoCMSWeb.BuilderLibrary.InputComponents do
  @moduledoc """
  Pure Phoenix renderers for builder input components.
  """

  use MangoCMSWeb, :html

  @doc "Renders a standalone input field preview."
  @spec input(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def input(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <label class={["form-control w-full", class_value(@classes, "custom")]}>
      <div :if={@props["label"] not in [nil, ""]} class="label">
        <span class="label-text">{@props["label"]}</span>
      </div>
      <input
        type={@props["input_type"] || "text"}
        name={@props["field_name"] || "field"}
        placeholder={@props["placeholder"] || ""}
        value={@props["value"] || ""}
        required={@props["required"] == true}
        disabled={@props["disabled"] == true}
        class={["input w-full", @props["style"] || "input-bordered"]}
      />
      <div :if={@props["help"] not in [nil, ""]} class="label">
        <span class="label-text-alt">{@props["help"]}</span>
      </div>
    </label>
    """
  end

  defp class_value(classes, key) when is_map(classes), do: Map.get(classes, key, "")
  defp class_value(_classes, _key), do: ""

  # ── Batch 1 additions ────────────────────────────────────────────────────────

  @doc "Renders a multi-line textarea field."
  @spec textarea(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def textarea(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <label class={["form-control w-full", class_value(@classes, "custom")]}>
      <div :if={@props["label"] not in [nil, ""]} class="label">
        <span class="label-text">{@props["label"]}</span>
        <span :if={@props["required"] == true} class="label-text-alt text-error">*</span>
      </div>
      <textarea
        name={@props["field_name"] || "field"}
        placeholder={@props["placeholder"] || ""}
        rows={@props["rows"] || 4}
        required={@props["required"] == true}
        disabled={@props["disabled"] == true}
        class={[
          "textarea w-full",
          textarea_style(@props["style"]),
          textarea_size(@props["size"]),
          @props["error"] == true && "textarea-error"
        ]}
      >{@props["value"] || ""}</textarea>
      <div class="label">
        <span
          :if={@props["error"] == true && @props["error_message"] not in [nil, ""]}
          class="label-text-alt text-error"
        >
          {@props["error_message"]}
        </span>
        <span :if={@props["help"] not in [nil, ""]} class="label-text-alt opacity-60">
          {@props["help"]}
        </span>
      </div>
    </label>
    """
  end

  @doc "Renders a form select dropdown."
  @spec select(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def select(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <label class={["form-control w-full", class_value(@classes, "custom")]}>
      <div :if={@props["label"] not in [nil, ""]} class="label">
        <span class="label-text">{@props["label"]}</span>
        <span :if={@props["required"] == true} class="label-text-alt text-error">*</span>
      </div>
      <select
        name={@props["field_name"] || "field"}
        required={@props["required"] == true}
        disabled={@props["disabled"] == true}
        multiple={@props["multiple"] == true}
        class={[
          "select w-full",
          select_style(@props["style"]),
          select_size(@props["size"]),
          @props["error"] == true && "select-error"
        ]}
      >
        <option disabled selected={@props["value"] in [nil, ""]}>
          {@props["placeholder"] || "Pick one"}
        </option>
        <option
          :for={opt <- form_select_options(@props)}
          value={opt["value"]}
          selected={opt["value"] == @props["value"]}
        >
          {opt["label"]}
        </option>
      </select>
      <div class="label">
        <span
          :if={@props["error"] == true && @props["error_message"] not in [nil, ""]}
          class="label-text-alt text-error"
        >
          {@props["error_message"]}
        </span>
        <span :if={@props["help"] not in [nil, ""]} class="label-text-alt opacity-60">
          {@props["help"]}
        </span>
      </div>
    </label>
    """
  end

  @doc "Renders a checkbox or checkbox group."
  @spec checkbox(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def checkbox(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["form-control", class_value(@classes, "custom")]}>
      <div :if={@props["group_label"] not in [nil, ""]} class="label">
        <span class="label-text font-medium">{@props["group_label"]}</span>
      </div>
      <%= if @props["mode"] == "group" do %>
        <div class={[checkbox_direction(@props["direction"]), "gap-2"]}>
          <label
            :for={opt <- checkbox_options(@props)}
            class="flex cursor-pointer items-center gap-3"
          >
            <input
              type="checkbox"
              name={"#{@props["field_name"] || "field"}[]"}
              value={opt["value"]}
              checked={opt["value"] in checkbox_checked_values(@props)}
              disabled={@props["disabled"] == true}
              class={[
                "checkbox",
                checkbox_tone(@props["tone"]),
                checkbox_size(@props["size"]),
                @props["error"] == true && "checkbox-error"
              ]}
            />
            <span class="label-text">{opt["label"]}</span>
          </label>
        </div>
      <% else %>
        <label class="flex cursor-pointer items-center gap-3">
          <input
            type="checkbox"
            name={@props["field_name"] || "field"}
            value={@props["value"] || "true"}
            checked={@props["checked"] == true}
            required={@props["required"] == true}
            disabled={@props["disabled"] == true}
            class={[
              "checkbox",
              checkbox_tone(@props["tone"]),
              checkbox_size(@props["size"]),
              @props["error"] == true && "checkbox-error"
            ]}
          />
          <span :if={@props["label"] not in [nil, ""]} class="label-text">
            {@props["label"]}
          </span>
        </label>
      <% end %>
      <div :if={@props["error"] == true && @props["error_message"] not in [nil, ""]} class="label">
        <span class="label-text-alt text-error">{@props["error_message"]}</span>
      </div>
      <div :if={@props["help"] not in [nil, ""]} class="label">
        <span class="label-text-alt opacity-60">{@props["help"]}</span>
      </div>
    </div>
    """
  end

  @doc "Renders a radio button group."
  @spec radio(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def radio(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["form-control", class_value(@classes, "custom")]}>
      <div :if={@props["label"] not in [nil, ""]} class="label">
        <span class="label-text font-medium">{@props["label"]}</span>
        <span :if={@props["required"] == true} class="label-text-alt text-error">*</span>
      </div>
      <div class={radio_direction(@props["direction"])}>
        <label :for={opt <- radio_options(@props)} class="flex cursor-pointer items-center gap-3">
          <input
            type="radio"
            name={@props["field_name"] || "field"}
            value={opt["value"]}
            checked={opt["value"] == @props["value"]}
            disabled={@props["disabled"] == true}
            class={[
              "radio",
              radio_tone(@props["tone"]),
              radio_size(@props["size"]),
              @props["error"] == true && "radio-error"
            ]}
          />
          <span class="label-text">{opt["label"]}</span>
        </label>
      </div>
      <div :if={@props["error"] == true && @props["error_message"] not in [nil, ""]} class="label">
        <span class="label-text-alt text-error">{@props["error_message"]}</span>
      </div>
      <div :if={@props["help"] not in [nil, ""]} class="label">
        <span class="label-text-alt opacity-60">{@props["help"]}</span>
      </div>
    </div>
    """
  end

  @doc "Renders a toggle switch."
  @spec toggle(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def toggle(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["form-control", class_value(@classes, "custom")]}>
      <label class="flex cursor-pointer items-center gap-3 py-1">
        <span
          :if={@props["label_position"] != "right" && @props["label"] not in [nil, ""]}
          class="label-text"
        >
          {@props["label"]}
        </span>
        <input
          type="checkbox"
          name={@props["field_name"] || "field"}
          value={@props["value"] || "true"}
          checked={@props["checked"] == true}
          disabled={@props["disabled"] == true}
          class={[
            "toggle",
            toggle_tone(@props["tone"]),
            toggle_size(@props["size"])
          ]}
        />
        <span
          :if={@props["label_position"] == "right" && @props["label"] not in [nil, ""]}
          class="label-text"
        >
          {@props["label"]}
        </span>
      </label>
      <div :if={@props["help"] not in [nil, ""]} class="label">
        <span class="label-text-alt opacity-60">{@props["help"]}</span>
      </div>
    </div>
    """
  end

  @doc "Renders a range slider."
  @spec range(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def range(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["form-control w-full", class_value(@classes, "custom")]}>
      <div class="flex items-center justify-between">
        <div :if={@props["label"] not in [nil, ""]} class="label">
          <span class="label-text">{@props["label"]}</span>
        </div>
        <span :if={@props["show_value"] == true} class="text-sm font-medium">
          {@props["value"] || @props["min"] || 0}
        </span>
      </div>
      <input
        type="range"
        name={@props["field_name"] || "field"}
        min={@props["min"] || 0}
        max={@props["max"] || 100}
        step={@props["step"] || 1}
        value={@props["value"] || 50}
        disabled={@props["disabled"] == true}
        class={[
          "range w-full",
          range_tone(@props["tone"]),
          range_size(@props["size"])
        ]}
      />
      <div
        :if={@props["show_steps"] == true}
        class="mt-1 flex w-full justify-between text-xs opacity-60"
      >
        <span :for={tick <- range_ticks(@props)}>{tick}</span>
      </div>
      <div :if={@props["help"] not in [nil, ""]} class="label">
        <span class="label-text-alt opacity-60">{@props["help"]}</span>
      </div>
    </div>
    """
  end

  @doc "Renders a star or heart rating input."
  @spec rating(map()) :: Phoenix.LiveView.Rendered.t()
  attr :node, :map, required: true
  attr :context, :map, default: %{}

  def rating(assigns) do
    assigns =
      assigns
      |> assign(:props, Map.get(assigns.node, "props", %{}))
      |> assign(:classes, Map.get(assigns.node, "classes", %{}))

    ~H"""
    <div class={["form-control", class_value(@classes, "custom")]}>
      <div :if={@props["label"] not in [nil, ""]} class="label">
        <span class="label-text">{@props["label"]}</span>
      </div>
      <div class={["rating", rating_size(@props["size"])]}>
        <input
          type="radio"
          name={@props["field_name"] || "rating"}
          class="rating-hidden"
          value="0"
        />
        <input
          :for={n <- 1..rating_count(@props)}
          type="radio"
          name={@props["field_name"] || "rating"}
          value={n}
          checked={n == rating_value(@props)}
          class={["mask", rating_shape(@props["shape"]), rating_color(@props["color"])]}
        />
      </div>
      <div :if={@props["help"] not in [nil, ""]} class="label">
        <span class="label-text-alt opacity-60">{@props["help"]}</span>
      </div>
    </div>
    """
  end

  # ── Input batch 1 helpers ─────────────────────────────────────────────────────

  defp textarea_style("ghost"), do: "textarea-ghost"
  defp textarea_style("primary"), do: "textarea-primary"
  defp textarea_style(_style), do: "textarea-bordered"

  defp textarea_size("xs"), do: "textarea-xs"
  defp textarea_size("sm"), do: "textarea-sm"
  defp textarea_size("lg"), do: "textarea-lg"
  defp textarea_size("xl"), do: "textarea-xl"
  defp textarea_size(_size), do: ""

  defp select_style("ghost"), do: "select-ghost"
  defp select_style("primary"), do: "select-primary"
  defp select_style(_style), do: "select-bordered"

  defp select_size("xs"), do: "select-xs"
  defp select_size("sm"), do: "select-sm"
  defp select_size("lg"), do: "select-lg"
  defp select_size("xl"), do: "select-xl"
  defp select_size(_size), do: ""

  defp form_select_options(%{"options" => opts}) when is_list(opts) and opts != [], do: opts

  defp form_select_options(_props) do
    [
      %{"label" => "Option 1", "value" => "1"},
      %{"label" => "Option 2", "value" => "2"},
      %{"label" => "Option 3", "value" => "3"}
    ]
  end

  defp checkbox_tone("primary"), do: "checkbox-primary"
  defp checkbox_tone("secondary"), do: "checkbox-secondary"
  defp checkbox_tone("accent"), do: "checkbox-accent"
  defp checkbox_tone("success"), do: "checkbox-success"
  defp checkbox_tone("warning"), do: "checkbox-warning"
  defp checkbox_tone("error"), do: "checkbox-error"
  defp checkbox_tone(_tone), do: ""

  defp checkbox_size("xs"), do: "checkbox-xs"
  defp checkbox_size("sm"), do: "checkbox-sm"
  defp checkbox_size("lg"), do: "checkbox-lg"
  defp checkbox_size("xl"), do: "checkbox-xl"
  defp checkbox_size(_size), do: ""

  defp checkbox_direction("horizontal"), do: "flex flex-row flex-wrap"
  defp checkbox_direction(_direction), do: "flex flex-col"

  defp checkbox_options(%{"options" => opts}) when is_list(opts) and opts != [], do: opts

  defp checkbox_options(_props) do
    [
      %{"label" => "Option A", "value" => "a"},
      %{"label" => "Option B", "value" => "b"},
      %{"label" => "Option C", "value" => "c"}
    ]
  end

  defp checkbox_checked_values(%{"checked_values" => vals}) when is_list(vals), do: vals
  defp checkbox_checked_values(%{"value" => val}) when is_binary(val) and val != "", do: [val]
  defp checkbox_checked_values(_props), do: []

  defp radio_options(%{"options" => opts}) when is_list(opts) and opts != [], do: opts

  defp radio_options(_props) do
    [
      %{"label" => "Option 1", "value" => "1"},
      %{"label" => "Option 2", "value" => "2"},
      %{"label" => "Option 3", "value" => "3"}
    ]
  end

  defp radio_direction("horizontal"), do: "flex flex-row flex-wrap gap-4"
  defp radio_direction(_direction), do: "flex flex-col gap-2"

  defp radio_tone("primary"), do: "radio-primary"
  defp radio_tone("secondary"), do: "radio-secondary"
  defp radio_tone("accent"), do: "radio-accent"
  defp radio_tone("success"), do: "radio-success"
  defp radio_tone("warning"), do: "radio-warning"
  defp radio_tone("error"), do: "radio-error"
  defp radio_tone(_tone), do: ""

  defp radio_size("xs"), do: "radio-xs"
  defp radio_size("sm"), do: "radio-sm"
  defp radio_size("lg"), do: "radio-lg"
  defp radio_size("xl"), do: "radio-xl"
  defp radio_size(_size), do: ""

  defp toggle_tone("primary"), do: "toggle-primary"
  defp toggle_tone("secondary"), do: "toggle-secondary"
  defp toggle_tone("accent"), do: "toggle-accent"
  defp toggle_tone("success"), do: "toggle-success"
  defp toggle_tone("warning"), do: "toggle-warning"
  defp toggle_tone("error"), do: "toggle-error"
  defp toggle_tone(_tone), do: ""

  defp toggle_size("xs"), do: "toggle-xs"
  defp toggle_size("sm"), do: "toggle-sm"
  defp toggle_size("lg"), do: "toggle-lg"
  defp toggle_size("xl"), do: "toggle-xl"
  defp toggle_size(_size), do: ""

  defp range_tone("primary"), do: "range-primary"
  defp range_tone("secondary"), do: "range-secondary"
  defp range_tone("accent"), do: "range-accent"
  defp range_tone("success"), do: "range-success"
  defp range_tone("warning"), do: "range-warning"
  defp range_tone("error"), do: "range-error"
  defp range_tone(_tone), do: ""

  defp range_size("xs"), do: "range-xs"
  defp range_size("sm"), do: "range-sm"
  defp range_size("lg"), do: "range-lg"
  defp range_size("xl"), do: "range-xl"
  defp range_size(_size), do: ""

  defp range_ticks(props) do
    min = to_range_int(Map.get(props, "min"), 0)
    max = to_range_int(Map.get(props, "max"), 100)
    step = to_range_int(Map.get(props, "step"), 25)

    if step > 0 and max > min do
      count = div(max - min, step) + 1
      Enum.map(0..(count - 1), fn i -> min + i * step end)
    else
      [min, max]
    end
  end

  defp to_range_int(val, _default) when is_integer(val), do: val

  defp to_range_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> default
    end
  end

  defp to_range_int(_val, default), do: default

  defp rating_size("xs"), do: "rating-xs"
  defp rating_size("sm"), do: "rating-sm"
  defp rating_size("lg"), do: "rating-lg"
  defp rating_size("xl"), do: "rating-xl"
  defp rating_size(_size), do: ""

  defp rating_shape("heart"), do: "mask-heart"
  defp rating_shape("diamond"), do: "mask-diamond"
  defp rating_shape(_shape), do: "mask-star-2"

  defp rating_color("primary"), do: "bg-primary"
  defp rating_color("secondary"), do: "bg-secondary"
  defp rating_color("accent"), do: "bg-accent"
  defp rating_color("warning"), do: "bg-warning"
  defp rating_color("error"), do: "bg-error"
  defp rating_color(_color), do: "bg-orange-400"

  defp rating_count(%{"count" => count}) when is_integer(count) and count > 0, do: min(count, 10)

  defp rating_count(%{"count" => count}) when is_binary(count) do
    case Integer.parse(count) do
      {int, _} when int > 0 -> min(int, 10)
      _ -> 5
    end
  end

  defp rating_count(_props), do: 5

  defp rating_value(%{"value" => val}) when is_integer(val), do: val

  defp rating_value(%{"value" => val}) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp rating_value(_props), do: 0
end
