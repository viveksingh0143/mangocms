defmodule MangoCMS.Tenant.Collections.CollectionField do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Collections.Collection

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @field_groups [
    {"Essentials",
     [
       {"String", "string"},
       {"Text", "text"},
       {"Rich Text", "rich_text"},
       {"Rich Content", "rich_content"},
       {"URL", "url"},
       {"Email", "email"},
       {"Number", "number"},
       {"Boolean", "boolean"},
       {"Color", "color"}
     ]},
    {"Organization & Reference",
     [
       {"Reference", "reference"},
       {"Multi-reference", "multi_reference"},
       {"Tags", "tags"},
       {"Category", "category"},
       {"Select", "select"}
     ]},
    {"Media",
     [
       {"Image", "image"},
       {"Media Gallery", "gallery"},
       {"Video", "video"},
       {"Audio", "audio"},
       {"Document", "document"},
       {"Multiple Documents", "documents"},
       {"Digital Asset", "asset"}
     ]},
    {"Time & Location",
     [
       {"Date", "date"},
       {"Date and Time", "datetime"},
       {"Time", "time"},
       {"Address", "address"}
     ]},
    {"Advanced Data Structures", [{"Object", "object"}, {"Array", "array"}, {"JSON", "json"}]}
  ]

  @field_types @field_groups
               |> Enum.flat_map(fn {_group, fields} -> Enum.map(fields, &elem(&1, 1)) end)

  @type t :: %__MODULE__{}

  schema "collection_fields" do
    field(:label, :string)
    field(:field_key, :string)
    field(:field_type, :string, default: "string")
    field(:required, :boolean, default: false)
    field(:indexed, :boolean, default: false)
    field(:filterable, :boolean, default: false)
    field(:sortable, :boolean, default: false)
    field(:unique, :boolean, default: false)
    field(:visible, :boolean, default: true)
    field(:primary, :boolean, default: false)
    field(:system, :boolean, default: false)
    field(:help_text, :string)
    field(:settings, :map, default: %{})
    field(:position, :integer, default: 0)

    belongs_to(:collection, Collection)

    timestamps()
  end

  def field_types, do: @field_types
  def field_type_options, do: @field_groups |> Enum.flat_map(fn {_group, fields} -> fields end)
  def field_type_groups, do: @field_groups

  def changeset(field, attrs) do
    field
    |> cast(attrs, [
      :label,
      :field_key,
      :field_type,
      :required,
      :indexed,
      :filterable,
      :sortable,
      :unique,
      :visible,
      :primary,
      :system,
      :help_text,
      :settings,
      :position
    ])
    |> normalize_map(:settings)
    |> maybe_put_field_key()
    |> normalize_change(:field_key, &keyify/1)
    |> prevent_custom_system_field()
    |> prevent_invalid_primary_field()
    |> put_indexed_for_queryable_fields()
    |> validate_required([:label, :field_key, :field_type, :settings, :position])
    |> validate_length(:label, min: 2, max: 120)
    |> validate_length(:field_key, min: 2, max: 80)
    |> validate_length(:help_text, max: 500)
    |> validate_format(:field_key, ~r/^[a-z][a-z0-9_]*$/,
      message: "must start with a letter and use lowercase letters, numbers and underscores"
    )
    |> validate_inclusion(:field_type, @field_types)
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:collection_id)
    |> unique_constraint(:field_key, name: :collection_fields_collection_id_field_key_index)
  end

  def queryable?(%__MODULE__{indexed: true}), do: true
  def queryable?(%__MODULE__{filterable: true}), do: true
  def queryable?(%__MODULE__{sortable: true}), do: true
  def queryable?(_field), do: false

  defp normalize_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _ -> put_change(changeset, field, %{})
    end
  end

  defp maybe_put_field_key(changeset) do
    field_key = get_field(changeset, :field_key)
    label = get_field(changeset, :label)

    if blank?(field_key) and is_binary(label) do
      put_change(changeset, :field_key, keyify(label))
    else
      changeset
    end
  end

  defp put_indexed_for_queryable_fields(changeset) do
    if get_field(changeset, :filterable) == true or get_field(changeset, :sortable) == true or
         get_field(changeset, :unique) == true do
      put_change(changeset, :indexed, true)
    else
      changeset
    end
  end

  defp prevent_custom_system_field(changeset) do
    put_change(changeset, :system, false)
  end

  defp prevent_invalid_primary_field(changeset) do
    if primary_field_type?(get_field(changeset, :field_type)) do
      changeset
    else
      put_change(changeset, :primary, false)
    end
  end

  def primary_field_type?(type) when is_binary(type) do
    type in ~w(string text rich_text rich_content email url number)
  end

  def primary_field_type?(_type), do: false

  defp normalize_change(changeset, field, normalizer) do
    case get_change(changeset, field) do
      value when is_binary(value) -> put_change(changeset, field, normalizer.(value))
      _ -> changeset
    end
  end

  defp keyify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9_]+/, "_")
    |> String.trim("_")
  end

  defp blank?(value), do: value in [nil, ""]
end
