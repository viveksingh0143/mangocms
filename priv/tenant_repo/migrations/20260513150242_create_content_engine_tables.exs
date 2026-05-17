defmodule MangoCMS.Tenant.Repo.Migrations.CreateContentEngineTables do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:content_types, primary_key: false) do
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

    create_if_not_exists(unique_index(:content_types, [:slug]))
    create_if_not_exists(index(:content_types, [:status]))
    create_if_not_exists(index(:content_types, [:archetype]))
    create_if_not_exists(index(:content_types, [:environment]))

    create_if_not_exists table(:content_type_fields, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:content_type_id, references(:content_types, type: :binary_id, on_delete: :delete_all),
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

    create_if_not_exists(unique_index(:content_type_fields, [:content_type_id, :field_key]))
    create_if_not_exists(index(:content_type_fields, [:content_type_id]))
    create_if_not_exists(index(:content_type_fields, [:field_type]))
    create_if_not_exists(index(:content_type_fields, [:indexed]))
    create_if_not_exists(index(:content_type_fields, [:filterable]))
    create_if_not_exists(index(:content_type_fields, [:sortable]))
    create_if_not_exists(index(:content_type_fields, [:unique]))
    create_if_not_exists(index(:content_type_fields, [:visible]))
    create_if_not_exists(index(:content_type_fields, [:primary]))
    create_if_not_exists(index(:content_type_fields, [:system]))

    create_if_not_exists table(:content_entries, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:content_type_id, references(:content_types, type: :binary_id, on_delete: :delete_all),
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

    create_if_not_exists(unique_index(:content_entries, [:content_type_id, :slug]))
    create_if_not_exists(index(:content_entries, [:content_type_id]))
    create_if_not_exists(index(:content_entries, [:owner_id]))
    create_if_not_exists(index(:content_entries, [:status]))
    create_if_not_exists(index(:content_entries, [:published_at]))
    create_if_not_exists(index(:content_entries, [:deleted_at]))

    create_if_not_exists table(:content_entry_indexes, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(
        :content_entry_id,
        references(:content_entries, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:content_type_id, references(:content_types, type: :binary_id, on_delete: :delete_all),
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

    create_if_not_exists(unique_index(:content_entry_indexes, [:content_entry_id, :field_key]))
    create_if_not_exists(index(:content_entry_indexes, [:content_entry_id]))
    create_if_not_exists(index(:content_entry_indexes, [:content_type_id, :field_key]))

    create_if_not_exists(
      index(:content_entry_indexes, [
        :content_type_id,
        :field_key,
        :string_value
      ])
    )

    create_if_not_exists(
      index(:content_entry_indexes, [
        :content_type_id,
        :field_key,
        :number_value
      ])
    )

    create_if_not_exists(
      index(:content_entry_indexes, [:content_type_id, :field_key, :bool_value])
    )

    create_if_not_exists(
      index(:content_entry_indexes, [
        :content_type_id,
        :field_key,
        :datetime_value
      ])
    )
  end

  def down do
    drop_if_exists(index(:content_entry_indexes, [:content_type_id, :field_key, :datetime_value]))
    drop_if_exists(index(:content_entry_indexes, [:content_type_id, :field_key, :bool_value]))
    drop_if_exists(index(:content_entry_indexes, [:content_type_id, :field_key, :number_value]))
    drop_if_exists(index(:content_entry_indexes, [:content_type_id, :field_key, :string_value]))
    drop_if_exists(index(:content_entry_indexes, [:content_type_id, :field_key]))
    drop_if_exists(index(:content_entry_indexes, [:content_entry_id]))
    drop_if_exists(unique_index(:content_entry_indexes, [:content_entry_id, :field_key]))
    drop_if_exists(table(:content_entry_indexes))

    drop_if_exists(index(:content_entries, [:deleted_at]))
    drop_if_exists(index(:content_entries, [:published_at]))
    drop_if_exists(index(:content_entries, [:status]))
    drop_if_exists(index(:content_entries, [:owner_id]))
    drop_if_exists(index(:content_entries, [:content_type_id]))
    drop_if_exists(unique_index(:content_entries, [:content_type_id, :slug]))
    drop_if_exists(table(:content_entries))

    drop_if_exists(index(:content_type_fields, [:system]))
    drop_if_exists(index(:content_type_fields, [:primary]))
    drop_if_exists(index(:content_type_fields, [:visible]))
    drop_if_exists(index(:content_type_fields, [:unique]))
    drop_if_exists(index(:content_type_fields, [:sortable]))
    drop_if_exists(index(:content_type_fields, [:filterable]))
    drop_if_exists(index(:content_type_fields, [:indexed]))
    drop_if_exists(index(:content_type_fields, [:field_type]))
    drop_if_exists(index(:content_type_fields, [:content_type_id]))
    drop_if_exists(unique_index(:content_type_fields, [:content_type_id, :field_key]))
    drop_if_exists(table(:content_type_fields))

    drop_if_exists(index(:content_types, [:environment]))
    drop_if_exists(index(:content_types, [:archetype]))
    drop_if_exists(index(:content_types, [:status]))
    drop_if_exists(unique_index(:content_types, [:slug]))
    drop_if_exists(table(:content_types))
  end
end
