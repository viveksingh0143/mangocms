defmodule MangoCMS.Tenant.Collections.CollectionItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Accounts.User
  alias MangoCMS.Tenant.Collections.{CollectionItemIndex, Collection, CollectionField}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @statuses ~w(draft published archived)

  @type t :: %__MODULE__{}

  schema "collection_items" do
    field(:title, :string)
    field(:slug, :string)
    field(:status, :string, default: "draft")
    field(:payload, :map, default: %{})
    field(:published_at, :utc_datetime)
    field(:deleted_at, :utc_datetime)

    belongs_to(:collection, Collection)
    belongs_to(:owner, User)
    has_many(:indexes, CollectionItemIndex)

    timestamps()
  end

  def status_options, do: Enum.map(@statuses, &{label(&1), &1})

  def changeset(entry, attrs, fields \\ []) do
    entry
    |> cast(attrs, [:title, :slug, :status, :payload, :published_at, :deleted_at])
    |> normalize_map(:payload)
    |> maybe_put_title()
    |> maybe_put_slug()
    |> normalize_change(:slug, &slugify/1)
    |> validate_required([:slug, :status, :payload])
    |> validate_length(:title, max: 160)
    |> validate_length(:slug, min: 1, max: 160)
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/,
      message: "only lowercase letters, numbers, underscores and hyphens"
    )
    |> validate_inclusion(:status, @statuses)
    |> validate_payload(fields)
    |> foreign_key_constraint(:collection_id)
    |> unique_constraint(:slug, name: :collection_items_collection_id_slug_index)
  end

  def publish_changeset(entry, fields \\ []) do
    entry
    |> changeset(%{status: "published", published_at: DateTime.utc_now(:second)}, fields)
  end

  def archive_changeset(entry, fields \\ []) do
    changeset(entry, %{status: "archived", deleted_at: DateTime.utc_now(:second)}, fields)
  end

  defp normalize_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _ -> put_change(changeset, field, %{})
    end
  end

  defp maybe_put_title(changeset) do
    title = get_field(changeset, :title)
    payload = get_field(changeset, :payload) || %{}
    fallback = Map.get(payload, "title") || Map.get(payload, "name")

    if blank?(title) and is_binary(fallback) do
      put_change(changeset, :title, fallback)
    else
      changeset
    end
  end

  defp maybe_put_slug(changeset) do
    slug = get_field(changeset, :slug)
    title = get_field(changeset, :title)

    if blank?(slug) and is_binary(title) do
      put_change(changeset, :slug, slugify(title))
    else
      changeset
    end
  end

  defp normalize_change(changeset, field, normalizer) do
    case get_change(changeset, field) do
      value when is_binary(value) -> put_change(changeset, field, normalizer.(value))
      _ -> changeset
    end
  end

  defp validate_payload(changeset, fields) do
    payload = get_field(changeset, :payload) || %{}

    Enum.reduce(fields, changeset, fn field, acc ->
      value = Map.get(payload, field.field_key)

      acc
      |> validate_required_payload_value(field, value)
      |> validate_payload_value(field, value)
    end)
  end

  defp validate_required_payload_value(
         changeset,
         %CollectionField{required: true} = field,
         value
       ) do
    if blank?(value) do
      add_error(changeset, :payload, "#{field.field_key} is required")
    else
      changeset
    end
  end

  defp validate_required_payload_value(changeset, _field, _value), do: changeset

  defp validate_payload_value(changeset, _field, value) when value in [nil, ""], do: changeset

  defp validate_payload_value(changeset, %CollectionField{field_type: type} = field, value) do
    settings = field.settings || %{}

    cond do
      not valid_value?(type, value, settings) ->
        add_error(changeset, :payload, "#{field.field_key} must be a valid #{type}")

      not valid_length?(type, value, settings) ->
        add_error(changeset, :payload, "#{field.field_key} must match length limits")

      true ->
        changeset
    end
  end

  defp valid_value?(type, value, _settings)
       when type in ~w(string text rich_text rich_content image video audio document asset url email color time address category reference),
       do: is_binary(value)

  defp valid_value?(type, value, _settings)
       when type in ~w(gallery documents tags multi_reference array) do
    is_list(value) and Enum.all?(value, &is_binary/1)
  end

  defp valid_value?(type, value, _settings) when type in ~w(object json), do: is_map(value)

  defp valid_value?("number", value, _settings) do
    is_number(value) or parsable_float?(value)
  end

  defp valid_value?("boolean", value, _settings) do
    is_boolean(value) or value in ["true", "false", "1", "0"]
  end

  defp valid_value?(type, value, _settings) when type in ~w(date datetime) do
    match?({:ok, _datetime}, cast_datetime(value))
  end

  defp valid_value?("select", value, settings) do
    options = Map.get(settings, "options")

    is_binary(value) and
      (not is_list(options) or options == [] or value in options)
  end

  defp valid_value?("json", _value, _settings), do: true
  defp valid_value?(_type, _value, _settings), do: false

  defp valid_length?(type, value, settings)
       when type in ~w(string text rich_text rich_content url email color) and is_binary(value) do
    length = String.length(value)
    min = integer_setting(settings, "min_length")
    max = integer_setting(settings, "max_length")

    (is_nil(min) or length >= min) and (is_nil(max) or length <= max)
  end

  defp valid_length?(_type, _value, _settings), do: true

  defp integer_setting(settings, key) do
    case Map.get(settings, key) do
      value when is_integer(value) and value >= 0 ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {integer, ""} when integer >= 0 -> integer
          _other -> nil
        end

      _other ->
        nil
    end
  end

  defp cast_datetime(%DateTime{} = value), do: {:ok, value}

  defp cast_datetime(%NaiveDateTime{} = value) do
    {:ok, DateTime.from_naive!(value, "Etc/UTC")}
  end

  defp cast_datetime(%Date{} = value) do
    value
    |> NaiveDateTime.new!(~T[00:00:00])
    |> DateTime.from_naive!("Etc/UTC")
    |> then(&{:ok, &1})
  end

  defp cast_datetime(value) when is_binary(value) do
    value = normalize_datetime_input(value)

    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        {:ok, datetime}

      {:error, _reason} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive} -> {:ok, DateTime.from_naive!(naive, "Etc/UTC")}
          {:error, _reason} -> :error
        end
    end
  end

  defp cast_datetime(_value), do: :error

  defp parsable_float?(value) when is_binary(value) do
    case Float.parse(value) do
      {_number, ""} -> true
      _other -> false
    end
  end

  defp parsable_float?(_value), do: false

  defp normalize_datetime_input(value) do
    value = String.trim(value)

    cond do
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/, value) ->
        value <> ":00"

      true ->
        value
    end
  end

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9_-]+/, "-")
    |> String.trim("-")
  end

  defp blank?(value), do: value in [nil, "", []]

  defp label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
