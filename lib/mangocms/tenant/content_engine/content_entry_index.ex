defmodule MangoCMS.Tenant.ContentEngine.ContentEntryIndex do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.ContentEngine.{ContentEntry, ContentType}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{}

  schema "content_entry_indexes" do
    field :field_key, :string
    field :field_type, :string
    field :string_value, :string
    field :number_value, :float
    field :bool_value, :boolean
    field :datetime_value, :utc_datetime

    belongs_to :content_entry, ContentEntry
    belongs_to :content_type, ContentType

    timestamps(updated_at: false)
  end

  def changeset(index, attrs) do
    index
    |> cast(attrs, [
      :content_entry_id,
      :content_type_id,
      :field_key,
      :field_type,
      :string_value,
      :number_value,
      :bool_value,
      :datetime_value
    ])
    |> validate_required([:content_entry_id, :content_type_id, :field_key, :field_type])
    |> validate_length(:field_key, min: 2, max: 80)
    |> validate_length(:field_type, min: 2, max: 40)
    |> foreign_key_constraint(:content_entry_id)
    |> foreign_key_constraint(:content_type_id)
    |> unique_constraint(:field_key,
      name: :content_entry_indexes_content_entry_id_field_key_index
    )
  end
end
