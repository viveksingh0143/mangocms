defmodule MangoCMSWeb.Builder.Field do
  @moduledoc """
  Helpers for declaring editable builder manifest fields.

  These helpers return plain Elixir maps so manifests stay declarative while
  inspector renderers can treat every component consistently.
  """

  @type option :: {String.t(), String.t()}

  @type t :: %{
          required(:key) => String.t(),
          required(:label) => String.t(),
          required(:type) => atom(),
          required(:scope) => :props | :classes | :settings | :slots,
          required(:bindable) => boolean(),
          required(:required) => boolean(),
          optional(:options) => [option()],
          optional(:help) => String.t(),
          optional(:placeholder) => String.t(),
          optional(:min) => number(),
          optional(:max) => number(),
          optional(:step) => number()
        }

  @doc "Declares a single-line text field."
  @spec text(String.t() | atom(), keyword()) :: t()
  def text(key, opts \\ []), do: build(:text, key, opts)

  @doc "Declares a multi-line text field."
  @spec textarea(String.t() | atom(), keyword()) :: t()
  def textarea(key, opts \\ []), do: build(:textarea, key, opts)

  @doc "Declares a select field with normalized label/value options."
  @spec select(String.t() | atom(), keyword()) :: t()
  def select(key, opts \\ []) do
    opts = Keyword.put(opts, :options, normalize_options(Keyword.get(opts, :options, [])))
    build(:select, key, opts)
  end

  @doc "Declares a boolean toggle field."
  @spec toggle(String.t() | atom(), keyword()) :: t()
  def toggle(key, opts \\ []), do: build(:toggle, key, opts)

  @doc "Declares a media picker field."
  @spec media(String.t() | atom(), keyword()) :: t()
  def media(key, opts \\ []), do: build(:media, key, opts)

  @doc "Declares an internal or external link field."
  @spec link(String.t() | atom(), keyword()) :: t()
  def link(key, opts \\ []), do: build(:link, key, opts)

  @doc "Declares an editable list of action buttons or links."
  @spec action_list(String.t() | atom(), keyword()) :: t()
  def action_list(key, opts \\ []), do: build(:action_list, key, opts)

  @doc "Declares an editable class token list."
  @spec class_list(String.t() | atom(), keyword()) :: t()
  def class_list(key, opts \\ []) do
    opts = Keyword.put_new(opts, :scope, :classes)
    build(:class_list, key, opts)
  end

  @doc "Declares a numeric field."
  @spec number(String.t() | atom(), keyword()) :: t()
  def number(key, opts \\ []), do: build(:number, key, opts)

  @doc "Declares a color field."
  @spec color(String.t() | atom(), keyword()) :: t()
  def color(key, opts \\ []), do: build(:color, key, opts)

  @doc "Declares an icon field."
  @spec icon(String.t() | atom(), keyword()) :: t()
  def icon(key, opts \\ []), do: build(:icon, key, opts)

  @doc "Declares a read-only slot controls field for an inspector."
  @spec slot_controls(String.t() | atom(), keyword()) :: t()
  def slot_controls(key \\ "slots", opts \\ []) do
    opts = Keyword.put_new(opts, :scope, :slots)
    build(:slot_controls, key, opts)
  end

  defp build(type, key, opts) do
    key = stringify_key(key)

    %{
      key: key,
      label: Keyword.get(opts, :label, humanize(key)),
      type: type,
      scope: Keyword.get(opts, :scope, :props),
      bindable: Keyword.get(opts, :bindable, false),
      required: Keyword.get(opts, :required, false)
    }
    |> maybe_put(:options, Keyword.get(opts, :options))
    |> maybe_put(:help, Keyword.get(opts, :help))
    |> maybe_put(:placeholder, Keyword.get(opts, :placeholder))
    |> maybe_put(:min, Keyword.get(opts, :min))
    |> maybe_put(:max, Keyword.get(opts, :max))
    |> maybe_put(:step, Keyword.get(opts, :step))
  end

  defp normalize_options(options) do
    Enum.map(options, fn
      {label, value} -> {to_string(label), to_string(value)}
      value -> {humanize(to_string(value)), to_string(value)}
    end)
  end

  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key), do: to_string(key)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp humanize(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
