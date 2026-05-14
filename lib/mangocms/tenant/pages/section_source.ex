defmodule MangoCMS.Tenant.Pages.SectionSource do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.ContentEngine.ContentType
  alias MangoCMS.Tenant.Pages.PageSection

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @statuses ~w(published all draft archived)
  @operators ~w(== != > >= < <= contains)

  @type t :: %__MODULE__{}

  schema "section_sources" do
    field :status, :string, default: "published"
    field :filters, :map, default: %{}
    field :sort, :map, default: %{}
    field :limit, :integer, default: 6
    field :offset, :integer, default: 0

    belongs_to :page_section, PageSection
    belongs_to :content_type, ContentType

    timestamps()
  end

  def status_options, do: Enum.map(@statuses, &{label(&1), &1})
  def operator_options, do: Enum.map(@operators, &{operator_label(&1), &1})

  def changeset(source, attrs) do
    source
    |> cast(attrs, [:content_type_id, :status, :filters, :sort, :limit, :offset])
    |> normalize_map(:filters)
    |> normalize_map(:sort)
    |> compact_filter()
    |> compact_sort()
    |> validate_required([:page_section_id, :content_type_id, :status, :filters, :sort, :limit])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:limit, greater_than: 0, less_than_or_equal_to: 50)
    |> validate_number(:offset, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:page_section_id)
    |> foreign_key_constraint(:content_type_id)
    |> unique_constraint(:page_section_id, name: :section_sources_page_section_id_index)
  end

  defp normalize_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _other -> put_change(changeset, field, %{})
    end
  end

  defp compact_filter(changeset) do
    filter = get_field(changeset, :filters) || %{}
    field = filter_value(filter, "field")
    value = filter_value(filter, "value")
    op = filter_value(filter, "op") || "=="

    if blank?(field) or blank?(value) do
      put_change(changeset, :filters, %{})
    else
      put_change(changeset, :filters, %{"field" => field, "op" => op, "value" => value})
    end
  end

  defp compact_sort(changeset) do
    sort = get_field(changeset, :sort) || %{}
    field = filter_value(sort, "field")
    direction = filter_value(sort, "direction") || "desc"

    if blank?(field) do
      put_change(changeset, :sort, %{})
    else
      put_change(changeset, :sort, %{"field" => field, "direction" => sort_direction(direction)})
    end
  end

  defp filter_value(map, key) do
    Map.get(map, key) || Map.get(map, known_atom_key(key))
  end

  defp known_atom_key("field"), do: :field
  defp known_atom_key("op"), do: :op
  defp known_atom_key("value"), do: :value
  defp known_atom_key("direction"), do: :direction
  defp known_atom_key(_key), do: nil

  defp sort_direction(direction) when direction in ["asc", :asc], do: "asc"
  defp sort_direction(_direction), do: "desc"

  defp blank?(value), do: value in [nil, ""]

  defp label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp operator_label("=="), do: "Equals"
  defp operator_label("!="), do: "Does not equal"
  defp operator_label(">"), do: "Greater than"
  defp operator_label(">="), do: "Greater than or equal"
  defp operator_label("<"), do: "Less than"
  defp operator_label("<="), do: "Less than or equal"
  defp operator_label("contains"), do: "Contains"
end
