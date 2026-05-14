defmodule MangoCMS.Tenant.Pages.PageSection do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Pages.{Page, SectionMapping, SectionSource}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @modes ~w(fixed dynamic reference)
  @types ~w(hero text cta feature_grid testimonial custom)

  @type t :: %__MODULE__{}

  schema "page_sections" do
    field :type, :string, default: "hero"
    field :template_id, :string, default: "default"
    field :mode, :string, default: "fixed"
    field :fixed_data, :map, default: %{}
    field :settings, :map, default: %{}
    field :position, :integer, default: 0

    belongs_to :page, Page
    has_one :source, SectionSource
    has_many :mappings, SectionMapping

    timestamps()
  end

  def type_options, do: Enum.map(@types, &{label(&1), &1})
  def mode_options, do: Enum.map(@modes, &{label(&1), &1})

  def changeset(section, attrs) do
    section
    |> cast(attrs, [:type, :template_id, :mode, :fixed_data, :settings, :position])
    |> normalize_map(:fixed_data)
    |> normalize_map(:settings)
    |> normalize_change(:type, &keyify/1)
    |> normalize_change(:template_id, &keyify/1)
    |> validate_required([
      :page_id,
      :type,
      :template_id,
      :mode,
      :fixed_data,
      :settings,
      :position
    ])
    |> validate_length(:type, min: 2, max: 80)
    |> validate_length(:template_id, min: 2, max: 80)
    |> validate_format(:type, ~r/^[a-z][a-z0-9_]*$/,
      message: "must start with a letter and use lowercase letters, numbers and underscores"
    )
    |> validate_format(:template_id, ~r/^[a-z][a-z0-9_]*$/,
      message: "must start with a letter and use lowercase letters, numbers and underscores"
    )
    |> validate_inclusion(:mode, @modes)
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:page_id)
  end

  defp normalize_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _other -> put_change(changeset, field, %{})
    end
  end

  defp normalize_change(changeset, field, normalizer) do
    case get_change(changeset, field) do
      value when is_binary(value) -> put_change(changeset, field, normalizer.(value))
      _other -> changeset
    end
  end

  defp keyify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9_]+/, "_")
    |> String.trim("_")
  end

  defp label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
