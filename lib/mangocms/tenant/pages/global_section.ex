defmodule MangoCMS.Tenant.Pages.GlobalSection do
  @moduledoc """
  Tenant-local reusable content tree that may be embedded in many pages.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Pages.GlobalSectionVersion

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{}

  schema "global_sections" do
    field :name, :string
    field :content_tree, {:array, :map}, default: []

    has_many :versions, GlobalSectionVersion

    timestamps()
  end

  @doc "Builds a changeset for a reusable global section."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(global_section, attrs) do
    global_section
    |> cast(attrs, [:name, :content_tree])
    |> normalize_tree()
    |> validate_required([:name, :content_tree])
    |> validate_length(:name, min: 2, max: 160)
    |> unique_constraint(:name, name: :global_sections_name_index)
  end

  defp normalize_tree(changeset) do
    case get_field(changeset, :content_tree) do
      value when is_list(value) -> changeset
      _other -> put_change(changeset, :content_tree, [])
    end
  end
end
