defmodule MangoCMS.Repo.Migrations.SetPlatformUserRoleDefaultToCustomer do
  use Ecto.Migration

  def up do
    unless sqlite?() do
      alter table(:users) do
        modify :role, :string, null: false, default: "customer"
      end
    end
  end

  def down do
    unless sqlite?() do
      alter table(:users) do
        modify :role, :string, null: false, default: "admin"
      end
    end
  end

  defp sqlite?, do: repo().__adapter__() == Ecto.Adapters.SQLite3
end
