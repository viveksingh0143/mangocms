defmodule MangoCMS.Tenant.Pages.GlobalSectionVersion do
  @moduledoc """
  Immutable append-only snapshot of a tenant global section content tree.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Accounts.User
  alias MangoCMS.Tenant.Pages.GlobalSection

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @snapshot_types ~w(auto manual publish_checkpoint)

  @type t :: %__MODULE__{}

  schema "global_section_versions" do
    field :content_tree, {:array, :map}
    field :version_number, :integer
    field :label, :string
    field :change_summary, :string
    field :snapshot_type, :string, default: "auto"
    field :restored_from, :integer

    belongs_to :global_section, GlobalSection
    belongs_to :created_by, User

    timestamps(updated_at: false)
  end

  @doc "Builds an immutable global section version changeset."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(global_section_version, attrs) do
    global_section_version
    |> cast(attrs, [
      :global_section_id,
      :created_by_id,
      :content_tree,
      :version_number,
      :label,
      :change_summary,
      :snapshot_type,
      :restored_from
    ])
    |> normalize_tree()
    |> validate_required([:global_section_id, :content_tree, :version_number, :snapshot_type])
    |> validate_number(:version_number, greater_than: 0)
    |> validate_inclusion(:snapshot_type, @snapshot_types)
    |> validate_length(:label, max: 160)
    |> validate_length(:change_summary, max: 500)
    |> foreign_key_constraint(:global_section_id)
    |> foreign_key_constraint(:created_by_id)
    |> unique_constraint([:global_section_id, :version_number])
  end

  defp normalize_tree(changeset) do
    case get_field(changeset, :content_tree) do
      value when is_list(value) -> changeset
      _other -> put_change(changeset, :content_tree, [])
    end
  end
end
