defmodule MangoCMS.Tenant.ContentEngine.ContentTypeField do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.ContentEngine.ContentType

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @field_types ~w(string text number boolean datetime image url select json)

  @type t :: %__MODULE__{}

  schema "content_type_fields" do
    field :label, :string
    field :field_key, :string
    field :field_type, :string, default: "string"
    field :required, :boolean, default: false
    field :indexed, :boolean, default: false
    field :filterable, :boolean, default: false
    field :sortable, :boolean, default: false
    field :settings, :map, default: %{}
    field :position, :integer, default: 0

    belongs_to :content_type, ContentType

    timestamps()
  end

  def field_types, do: @field_types
  def field_type_options, do: Enum.map(@field_types, &{label(&1), &1})

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
      :settings,
      :position
    ])
    |> normalize_map(:settings)
    |> maybe_put_field_key()
    |> normalize_change(:field_key, &keyify/1)
    |> put_indexed_for_queryable_fields()
    |> validate_required([:label, :field_key, :field_type, :settings, :position])
    |> validate_length(:label, min: 2, max: 120)
    |> validate_length(:field_key, min: 2, max: 80)
    |> validate_format(:field_key, ~r/^[a-z][a-z0-9_]*$/,
      message: "must start with a letter and use lowercase letters, numbers and underscores"
    )
    |> validate_inclusion(:field_type, @field_types)
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:content_type_id)
    |> unique_constraint(:field_key, name: :content_type_fields_content_type_id_field_key_index)
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
    if get_field(changeset, :filterable) == true or get_field(changeset, :sortable) == true do
      put_change(changeset, :indexed, true)
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

  defp keyify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9_]+/, "_")
    |> String.trim("_")
  end

  defp blank?(value), do: value in [nil, ""]

  defp label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
