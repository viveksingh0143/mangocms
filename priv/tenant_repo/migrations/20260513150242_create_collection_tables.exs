defmodule MangoCMS.Tenant.Repo.Migrations.CreateCollectionsTables do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:collections, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:slug, :string, null: false)
      add(:description, :string)
      add(:status, :string, null: false, default: "active")
      add(:archetype, :string, null: false, default: "content")
      add(:item_mode, :string, null: false, default: "multiple")
      add(:environment, :string, null: false, default: "live")
      add(:settings, :map, null: false, default: %{})

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists(unique_index(:collections, [:slug]))
    create_if_not_exists(index(:collections, [:status]))
    create_if_not_exists(index(:collections, [:archetype]))
    create_if_not_exists(index(:collections, [:environment]))

    create_if_not_exists table(:collection_fields, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:collection_id, references(:collections, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:label, :string, null: false)
      add(:field_key, :string, null: false)
      add(:field_type, :string, null: false)
      add(:required, :boolean, null: false, default: false)
      add(:indexed, :boolean, null: false, default: false)
      add(:filterable, :boolean, null: false, default: false)
      add(:sortable, :boolean, null: false, default: false)
      add(:unique, :boolean, null: false, default: false)
      add(:visible, :boolean, null: false, default: true)
      add(:primary, :boolean, null: false, default: false)
      add(:system, :boolean, null: false, default: false)
      add(:help_text, :string)
      add(:settings, :map, null: false, default: %{})
      add(:position, :integer, null: false, default: 0)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists(unique_index(:collection_fields, [:collection_id, :field_key]))
    create_if_not_exists(index(:collection_fields, [:collection_id]))
    create_if_not_exists(index(:collection_fields, [:field_type]))
    create_if_not_exists(index(:collection_fields, [:indexed]))
    create_if_not_exists(index(:collection_fields, [:filterable]))
    create_if_not_exists(index(:collection_fields, [:sortable]))
    create_if_not_exists(index(:collection_fields, [:unique]))
    create_if_not_exists(index(:collection_fields, [:visible]))
    create_if_not_exists(index(:collection_fields, [:primary]))
    create_if_not_exists(index(:collection_fields, [:system]))

    create_if_not_exists table(:collection_items, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:collection_id, references(:collections, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:owner_id, references(:users, type: :binary_id, on_delete: :nilify_all))
      add(:title, :string)
      add(:slug, :string, null: false)
      add(:status, :string, null: false, default: "draft")
      add(:payload, :map, null: false, default: %{})
      add(:published_at, :utc_datetime)
      add(:deleted_at, :utc_datetime)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists(unique_index(:collection_items, [:collection_id, :slug]))
    create_if_not_exists(index(:collection_items, [:collection_id]))
    create_if_not_exists(index(:collection_items, [:owner_id]))
    create_if_not_exists(index(:collection_items, [:status]))
    create_if_not_exists(index(:collection_items, [:published_at]))
    create_if_not_exists(index(:collection_items, [:deleted_at]))

    create_if_not_exists table(:collection_item_indexes, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(
        :collection_item_id,
        references(:collection_items, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:collection_id, references(:collections, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:field_key, :string, null: false)
      add(:field_type, :string, null: false)
      add(:string_value, :string)
      add(:number_value, :float)
      add(:bool_value, :boolean)
      add(:datetime_value, :utc_datetime)

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create_if_not_exists(
      unique_index(:collection_item_indexes, [:collection_item_id, :field_key])
    )

    create_if_not_exists(index(:collection_item_indexes, [:collection_item_id]))
    create_if_not_exists(index(:collection_item_indexes, [:collection_id, :field_key]))

    create_if_not_exists(
      index(:collection_item_indexes, [
        :collection_id,
        :field_key,
        :string_value
      ])
    )

    create_if_not_exists(
      index(:collection_item_indexes, [
        :collection_id,
        :field_key,
        :number_value
      ])
    )

    create_if_not_exists(
      index(:collection_item_indexes, [:collection_id, :field_key, :bool_value])
    )

    create_if_not_exists(
      index(:collection_item_indexes, [
        :collection_id,
        :field_key,
        :datetime_value
      ])
    )
  end

  def down do
    drop_if_exists(index(:collection_item_indexes, [:collection_id, :field_key, :datetime_value]))
    drop_if_exists(index(:collection_item_indexes, [:collection_id, :field_key, :bool_value]))
    drop_if_exists(index(:collection_item_indexes, [:collection_id, :field_key, :number_value]))
    drop_if_exists(index(:collection_item_indexes, [:collection_id, :field_key, :string_value]))
    drop_if_exists(index(:collection_item_indexes, [:collection_id, :field_key]))
    drop_if_exists(index(:collection_item_indexes, [:collection_item_id]))
    drop_if_exists(unique_index(:collection_item_indexes, [:collection_item_id, :field_key]))
    drop_if_exists(table(:collection_item_indexes))

    drop_if_exists(index(:collection_items, [:deleted_at]))
    drop_if_exists(index(:collection_items, [:published_at]))
    drop_if_exists(index(:collection_items, [:status]))
    drop_if_exists(index(:collection_items, [:owner_id]))
    drop_if_exists(index(:collection_items, [:collection_id]))
    drop_if_exists(unique_index(:collection_items, [:collection_id, :slug]))
    drop_if_exists(table(:collection_items))

    drop_if_exists(index(:collection_fields, [:system]))
    drop_if_exists(index(:collection_fields, [:primary]))
    drop_if_exists(index(:collection_fields, [:visible]))
    drop_if_exists(index(:collection_fields, [:unique]))
    drop_if_exists(index(:collection_fields, [:sortable]))
    drop_if_exists(index(:collection_fields, [:filterable]))
    drop_if_exists(index(:collection_fields, [:indexed]))
    drop_if_exists(index(:collection_fields, [:field_type]))
    drop_if_exists(index(:collection_fields, [:collection_id]))
    drop_if_exists(unique_index(:collection_fields, [:collection_id, :field_key]))
    drop_if_exists(table(:collection_fields))

    drop_if_exists(index(:collections, [:environment]))
    drop_if_exists(index(:collections, [:archetype]))
    drop_if_exists(index(:collections, [:status]))
    drop_if_exists(unique_index(:collections, [:slug]))
    drop_if_exists(table(:collections))
  end
end
