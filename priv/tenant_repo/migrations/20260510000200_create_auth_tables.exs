defmodule MangoCMS.Tenant.Repo.Migrations.CreateAuthTables do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :identity_key, :string, null: false
      add :email, :string, null: false
      add :hashed_password, :string
      add :full_name, :string
      add :phone, :string
      add :avatar_url, :string
      add :locale, :string, null: false, default: "en"
      add :timezone, :string, null: false, default: "UTC"
      add :role, :string, null: false, default: "member"
      add :confirmed_at, :utc_datetime
      add :disabled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:users, [:identity_key])
    create_if_not_exists index(:users, [:email])
    create_if_not_exists index(:users, [:role])

    create_if_not_exists table(:user_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create_if_not_exists unique_index(:user_tokens, [:token, :context])
    create_if_not_exists index(:user_tokens, [:user_id])
  end

  def down do
    drop_if_exists index(:user_tokens, [:user_id])
    drop_if_exists unique_index(:user_tokens, [:token, :context])
    drop_if_exists table(:user_tokens)

    drop_if_exists index(:users, [:role])
    drop_if_exists index(:users, [:email])
    drop_if_exists unique_index(:users, [:identity_key])
    drop_if_exists table(:users)
  end
end
