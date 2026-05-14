defmodule MangoCMS.Tenant.Pages.SectionMapping do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Pages.PageSection

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @slots ~w(eyebrow title subtitle body image cta_label cta_href badge price meta)
  @formatters ~w(text excerpt number currency date image url badge)

  @type t :: %__MODULE__{}

  schema "section_mappings" do
    field :slot, :string
    field :source_path, :string
    field :formatter, :string, default: "text"
    field :settings, :map, default: %{}
    field :position, :integer, default: 0

    belongs_to :page_section, PageSection

    timestamps()
  end

  def slots, do: @slots
  def slot_options, do: Enum.map(@slots, &{label(&1), &1})
  def formatter_options, do: Enum.map(@formatters, &{label(&1), &1})

  def changeset(mapping, attrs) do
    mapping
    |> cast(attrs, [:slot, :source_path, :formatter, :settings, :position])
    |> normalize_map(:settings)
    |> normalize_change(:slot, &keyify/1)
    |> normalize_change(:formatter, &keyify/1)
    |> normalize_change(:source_path, &normalize_source_path/1)
    |> validate_required([
      :page_section_id,
      :slot,
      :source_path,
      :formatter,
      :settings,
      :position
    ])
    |> validate_inclusion(:slot, @slots)
    |> validate_inclusion(:formatter, @formatters)
    |> validate_length(:source_path, min: 1, max: 160)
    |> validate_format(:source_path, ~r/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$/,
      message: "must be a dot path like payload.title or title"
    )
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:page_section_id)
    |> unique_constraint(:slot, name: :section_mappings_page_section_id_slot_index)
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

  defp normalize_source_path(value) do
    value
    |> String.trim()
    |> String.downcase()
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
