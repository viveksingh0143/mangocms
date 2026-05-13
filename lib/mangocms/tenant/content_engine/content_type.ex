defmodule MangoCMS.Tenant.ContentEngine.ContentType do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.ContentEngine.{ContentEntry, ContentTypeField}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @statuses ~w(active archived)

  @type t :: %__MODULE__{}

  schema "content_types" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :status, :string, default: "active"
    field :settings, :map, default: %{}

    has_many :fields, ContentTypeField
    has_many :entries, ContentEntry

    timestamps()
  end

  def status_options, do: Enum.map(@statuses, &{label(&1), &1})

  def changeset(content_type, attrs) do
    content_type
    |> cast(attrs, [:name, :slug, :description, :status, :settings])
    |> normalize_map(:settings)
    |> maybe_put_slug()
    |> normalize_change(:slug, &slugify/1)
    |> validate_required([:name, :slug, :status, :settings])
    |> validate_length(:name, min: 2, max: 120)
    |> validate_length(:slug, min: 2, max: 120)
    |> validate_length(:description, max: 500)
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/,
      message: "only lowercase letters, numbers, underscores and hyphens"
    )
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:slug, name: :content_types_slug_index)
  end

  defp normalize_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _ -> put_change(changeset, field, %{})
    end
  end

  defp maybe_put_slug(changeset) do
    slug = get_field(changeset, :slug)
    name = get_field(changeset, :name)

    if blank?(slug) and is_binary(name) do
      put_change(changeset, :slug, slugify(name))
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

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9_-]+/, "-")
    |> String.trim("-")
  end

  defp blank?(value), do: value in [nil, ""]

  defp label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
