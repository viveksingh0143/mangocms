defmodule MangoCMS.Tenant.Pages.Section do
  @moduledoc """
  Tenant-local reusable section template.

  A section owns a content tree and optional data-source metadata. Pages embed a
  section's tree into their own `content_tree`; they do not own section rows.
  Dynamic values may be expressed in element props as placeholders such as
  `{{title}}` or `{{price}}` and resolved from `source_config` when rendered by a
  dynamic loop.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Pages.SectionVersion

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @modes ~w(static dynamic reference)

  @type t :: %__MODULE__{}

  schema "sections" do
    field :name, :string
    field :template_key, :string, default: "custom"
    field :group_label, :string, default: "General"
    field :mode, :string, default: "static"
    field :settings, :map, default: %{}
    field :source_config, :map, default: %{}
    field :filters, :map, default: %{}
    field :loop_settings, :map, default: %{"enabled" => false, "limit" => 6}
    field :content_tree, {:array, :map}, default: []

    has_many :versions, SectionVersion

    timestamps()
  end

  @doc "Returns section mode options."
  @spec mode_options() :: [{String.t(), String.t()}]
  def mode_options, do: [{"Static", "static"}, {"Dynamic", "dynamic"}, {"Reference", "reference"}]

  @doc "Builds a changeset for a reusable section."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(section, attrs) do
    section
    |> cast(attrs, [
      :name,
      :template_key,
      :group_label,
      :mode,
      :settings,
      :source_config,
      :filters,
      :loop_settings,
      :content_tree
    ])
    |> normalize_tree()
    |> normalize_maps()
    |> validate_required([:name, :template_key, :group_label, :mode, :content_tree])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:template_key, min: 2, max: 120)
    |> validate_length(:group_label, min: 2, max: 80)
    |> validate_inclusion(:mode, @modes)
    |> unique_constraint(:name, name: :sections_name_index)
  end

  defp normalize_tree(changeset) do
    case get_field(changeset, :content_tree) do
      value when is_list(value) -> changeset
      _other -> put_change(changeset, :content_tree, [])
    end
  end

  defp normalize_maps(changeset) do
    changeset
    |> normalize_map(:settings)
    |> normalize_map(:source_config)
    |> normalize_map(:filters)
    |> normalize_map(:loop_settings, %{"enabled" => false, "limit" => 6})
  end

  defp normalize_map(changeset, field, default \\ %{}) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _other -> put_change(changeset, field, default)
    end
  end
end
