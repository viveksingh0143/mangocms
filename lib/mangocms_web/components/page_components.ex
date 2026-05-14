defmodule MangoCMSWeb.PageComponents do
  @moduledoc "Public tenant page rendering components."

  use MangoCMSWeb, :html

  alias MangoCMS.Tenant.Pages.PageSection

  attr :page, :any, required: true
  attr :sections, :list, required: true
  attr :section_items, :map, default: %{}

  def tenant_page(assigns) do
    ~H"""
    <main id="tenant-page" class="bg-base-100 text-base-content">
      <.page_section
        :for={section <- @sections}
        section={section}
        items={Map.get(@section_items, section.id, [])}
      />
    </main>
    """
  end

  attr :section, PageSection, required: true
  attr :items, :list, default: []

  def page_section(%{section: %PageSection{mode: "fixed"}} = assigns) do
    fixed_section(assigns)
  end

  def page_section(%{section: %PageSection{mode: mode}, items: items} = assigns)
      when mode in ["dynamic", "reference"] and items != [] do
    assigns =
      assigns
      |> assign(:data, safe_map(assigns.section.fixed_data))
      |> assign(:mappings, mappings_by_slot(assigns.section))

    ~H"""
    <section id={"section-#{@section.id}"} class="bg-base-100">
      <div class="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <div :if={present?(@data["title"]) || present?(@data["subtitle"])} class="mb-8 max-w-3xl">
          <p
            :if={present?(@data["eyebrow"])}
            class="mb-3 text-sm font-semibold uppercase tracking-wide text-primary"
          >
            {@data["eyebrow"]}
          </p>
          <h2 :if={present?(@data["title"])} class="text-3xl font-bold tracking-tight">
            {@data["title"]}
          </h2>
          <p :if={present?(@data["subtitle"])} class="mt-3 text-base text-base-content/70">
            {@data["subtitle"]}
          </p>
        </div>

        <div class="grid gap-5 md:grid-cols-2 lg:grid-cols-3">
          <article :for={item <- @items} class="card border border-base-300 bg-base-100 shadow-sm">
            <figure :if={present?(mapped_value(item, @mappings, "image"))}>
              <img
                src={mapped_value(item, @mappings, "image")}
                alt={text_or(mapped_value(item, @mappings, "title"), "Content image")}
                class="aspect-video w-full object-cover"
              />
            </figure>
            <div class="card-body">
              <div class="flex flex-wrap items-center gap-2">
                <span
                  :if={present?(mapped_value(item, @mappings, "badge"))}
                  class="badge badge-primary badge-outline"
                >
                  {mapped_value(item, @mappings, "badge")}
                </span>
                <span
                  :if={present?(mapped_value(item, @mappings, "price"))}
                  class="badge badge-neutral"
                >
                  {mapped_value(item, @mappings, "price")}
                </span>
              </div>

              <h3 class="card-title">
                {text_or(mapped_value(item, @mappings, "title"), "Untitled entry")}
              </h3>
              <p :if={present?(mapped_value(item, @mappings, "subtitle"))}>
                {mapped_value(item, @mappings, "subtitle")}
              </p>
              <p
                :if={present?(mapped_value(item, @mappings, "body"))}
                class="text-sm text-base-content/70"
              >
                {mapped_value(item, @mappings, "body")}
              </p>

              <div :if={present?(mapped_value(item, @mappings, "cta_href"))} class="card-actions mt-2">
                <.link href={mapped_value(item, @mappings, "cta_href")} class="btn btn-sm btn-outline">
                  {text_or(mapped_value(item, @mappings, "cta_label"), "View")}
                </.link>
              </div>
            </div>
          </article>
        </div>
      </div>
    </section>
    """
  end

  def page_section(assigns) do
    ~H"""
    """
  end

  def fixed_section(%{section: %PageSection{mode: "fixed", type: "hero"}} = assigns) do
    assigns = assign(assigns, :data, safe_map(assigns.section.fixed_data))

    ~H"""
    <section id={"section-#{@section.id}"} class="hero min-h-[32rem] bg-base-100">
      <div class="hero-content grid max-w-7xl gap-10 px-4 py-20 lg:grid-cols-[1.05fr_0.95fr]">
        <div>
          <p
            :if={present?(@data["eyebrow"])}
            class="mb-3 text-sm font-semibold uppercase tracking-wide text-primary"
          >
            {@data["eyebrow"]}
          </p>
          <h1 class="text-4xl font-bold tracking-tight sm:text-5xl">
            {text_or(@data["title"], "Untitled page section")}
          </h1>
          <p
            :if={present?(@data["subtitle"])}
            class="mt-5 max-w-2xl text-lg leading-8 text-base-content/70"
          >
            {@data["subtitle"]}
          </p>
          <div :if={present?(@data["cta_label"])} class="mt-8">
            <.link href={text_or(@data["cta_href"], "#")} class="btn btn-primary">
              {@data["cta_label"]}
            </.link>
          </div>
        </div>

        <div
          :if={present?(@data["image_url"])}
          class="overflow-hidden rounded-lg border border-base-300 bg-base-200 shadow-sm"
        >
          <img
            src={@data["image_url"]}
            alt={text_or(@data["title"], "Page section image")}
            class="aspect-video w-full object-cover"
          />
        </div>
      </div>
    </section>
    """
  end

  def fixed_section(%{section: %PageSection{mode: "fixed", type: "cta"}} = assigns) do
    assigns = assign(assigns, :data, safe_map(assigns.section.fixed_data))

    ~H"""
    <section id={"section-#{@section.id}"} class="bg-base-200">
      <div class="mx-auto max-w-5xl px-4 py-16 text-center sm:px-6 lg:px-8">
        <p
          :if={present?(@data["eyebrow"])}
          class="mb-3 text-sm font-semibold uppercase tracking-wide text-primary"
        >
          {@data["eyebrow"]}
        </p>
        <h2 class="text-3xl font-bold tracking-tight sm:text-4xl">
          {text_or(@data["title"], "Ready to begin?")}
        </h2>
        <p
          :if={present?(@data["subtitle"])}
          class="mx-auto mt-4 max-w-2xl text-base leading-7 text-base-content/70"
        >
          {@data["subtitle"]}
        </p>
        <div :if={present?(@data["cta_label"])} class="mt-8">
          <.link href={text_or(@data["cta_href"], "#")} class="btn btn-primary">
            {@data["cta_label"]}
          </.link>
        </div>
      </div>
    </section>
    """
  end

  def fixed_section(%{section: %PageSection{mode: "fixed"}} = assigns) do
    assigns = assign(assigns, :data, safe_map(assigns.section.fixed_data))

    ~H"""
    <section id={"section-#{@section.id}"} class="bg-base-100">
      <div class="mx-auto max-w-4xl px-4 py-14 sm:px-6 lg:px-8">
        <p
          :if={present?(@data["eyebrow"])}
          class="mb-3 text-sm font-semibold uppercase tracking-wide text-primary"
        >
          {@data["eyebrow"]}
        </p>
        <h2 class="text-3xl font-bold tracking-tight">
          {text_or(@data["title"], "Untitled section")}
        </h2>
        <p :if={present?(@data["subtitle"])} class="mt-4 text-base leading-7 text-base-content/70">
          {@data["subtitle"]}
        </p>
        <p
          :if={present?(@data["body"])}
          class="mt-6 whitespace-pre-line text-base leading-7 text-base-content/80"
        >
          {@data["body"]}
        </p>
        <div :if={present?(@data["cta_label"])} class="mt-8">
          <.link href={text_or(@data["cta_href"], "#")} class="btn btn-outline">
            {@data["cta_label"]}
          </.link>
        </div>
      </div>
    </section>
    """
  end

  def fixed_section(assigns) do
    ~H"""
    """
  end

  defp safe_map(value) when is_map(value), do: value
  defp safe_map(_value), do: %{}

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp text_or(value, fallback) when is_binary(value) do
    case String.trim(value) do
      "" -> fallback
      text -> text
    end
  end

  defp text_or(_value, fallback), do: fallback

  defp mappings_by_slot(%PageSection{mappings: mappings}) when is_list(mappings) do
    Map.new(mappings, &{&1.slot, &1})
  end

  defp mappings_by_slot(_section), do: %{}

  defp mapped_value(entry, mappings, slot) do
    case Map.get(mappings, slot) do
      %{source_path: source_path, formatter: formatter, settings: settings} ->
        entry
        |> path_value(source_path)
        |> format_value(formatter, settings || %{})

      _mapping ->
        nil
    end
  end

  defp path_value(entry, "payload." <> path) do
    entry
    |> Map.get(:payload, %{})
    |> get_in(String.split(path, "."))
  end

  defp path_value(entry, "title"), do: Map.get(entry, :title)
  defp path_value(entry, "slug"), do: Map.get(entry, :slug)
  defp path_value(entry, "status"), do: Map.get(entry, :status)
  defp path_value(entry, "published_at"), do: Map.get(entry, :published_at)
  defp path_value(_entry, _path), do: nil

  defp format_value(nil, _formatter, _settings), do: nil
  defp format_value("", _formatter, _settings), do: nil
  defp format_value(value, "image", _settings), do: to_string(value)
  defp format_value(value, "url", _settings), do: url_value(value)
  defp format_value(value, "currency", settings), do: currency_value(value, settings)
  defp format_value(value, "date", _settings), do: date_value(value)
  defp format_value(value, "number", _settings), do: number_value(value)
  defp format_value(value, "excerpt", settings), do: excerpt_value(value, settings)
  defp format_value(value, _formatter, _settings), do: to_string(value)

  defp url_value(value) when is_binary(value) do
    cond do
      String.starts_with?(value, ["/", "http://", "https://", "#"]) -> value
      true -> "/" <> value
    end
  end

  defp url_value(value), do: to_string(value)

  defp currency_value(value, settings) do
    currency = Map.get(settings, "currency", "INR")

    amount =
      case value do
        value when is_integer(value) -> value / 100
        value when is_float(value) -> value / 100
        value when is_binary(value) -> parse_float(value) / 100
        _other -> 0.0
      end

    symbol =
      case currency do
        "USD" -> "USD "
        "EUR" -> "EUR "
        "GBP" -> "GBP "
        _other -> "INR "
      end

    symbol <> :erlang.float_to_binary(amount, decimals: 2)
  end

  defp date_value(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y")
  defp date_value(%Date{} = value), do: Calendar.strftime(value, "%b %d, %Y")

  defp date_value(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> date_value(datetime)
      {:error, _reason} -> value
    end
  end

  defp date_value(value), do: to_string(value)

  defp number_value(value) when is_integer(value), do: Integer.to_string(value)
  defp number_value(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 2)
  defp number_value(value), do: to_string(value)

  defp excerpt_value(value, settings) do
    limit =
      case Map.get(settings, "limit", 140) do
        value when is_integer(value) -> value
        value when is_binary(value) -> round(parse_float(value))
        _other -> 140
      end

    value
    |> to_string()
    |> String.trim()
    |> String.slice(0, limit)
  end

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {number, _rest} -> number
      :error -> 0.0
    end
  end

  defp parse_float(value) when is_number(value), do: value / 1
  defp parse_float(_value), do: 0.0
end
