defmodule MangoCMS.Tenant.Collections.CollectionItemIndex do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Collections.{CollectionItem, Collection}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{}

  schema "collection_item_indexes" do
    field :field_key, :string
    field :field_type, :string
    field :string_value, :string
    field :number_value, :float
    field :bool_value, :boolean
    field :datetime_value, :utc_datetime

    belongs_to :collection_item, CollectionItem
    belongs_to :collection, Collection

    timestamps(updated_at: false)
  end

  def changeset(index, attrs) do
    index
    |> cast(attrs, [
      :collection_item_id,
      :collection_id,
      :field_key,
      :field_type,
      :string_value,
      :number_value,
      :bool_value,
      :datetime_value
    ])
    |> validate_required([:collection_item_id, :collection_id, :field_key, :field_type])
    |> validate_length(:field_key, min: 2, max: 80)
    |> validate_length(:field_type, min: 2, max: 40)
    |> foreign_key_constraint(:collection_item_id)
    |> foreign_key_constraint(:collection_id)
    |> unique_constraint(:field_key,
      name: :collection_item_indexes_collection_item_id_field_key_index
    )
  end
end
