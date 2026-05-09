defmodule MangoCMS.Repo.Migrations.CreateAuthTables do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all)
      add :scope, :string, null: false
      add :identity_key, :string, null: false

      add :email, :string, null: false
      add :hashed_password, :string
      add :full_name, :string
      add :phone, :string
      add :avatar_url, :string
      add :locale, :string, null: false, default: "en"
      add :timezone, :string, null: false, default: "UTC"
      add :role, :string, null: false, default: "admin"
      add :confirmed_at, :utc_datetime
      add :disabled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:identity_key])
    create index(:users, [:tenant_id])
    create index(:users, [:scope])
    create index(:users, [:email])

    create table(:user_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create unique_index(:user_tokens, [:token, :context])
    create index(:user_tokens, [:user_id])

    create table(:user_identities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all)
      add :scope, :string, null: false
      add :provider, :string, null: false
      add :provider_uid, :string, null: false
      add :identity_key, :string, null: false
      add :email, :string
      add :name, :string
      add :avatar_url, :string
      add :raw_data, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_identities, [:identity_key])
    create index(:user_identities, [:user_id])
    create index(:user_identities, [:tenant_id])
  end
end
