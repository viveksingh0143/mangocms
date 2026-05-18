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

  @modes ~w(static dynamic reference fixed collection)
  @statuses ~w(draft published archived)

  @type t :: %__MODULE__{}

  schema "sections" do
    field :name, :string
    field :template_key, :string, default: "custom"
    field :group_label, :string, default: "General"
    field :mode, :string, default: "static"
    field :status, :string, default: "draft"
    field :settings, :map, default: %{}
    field :source_config, :map, default: %{}
    field :filters, :map, default: %{}
    field :loop_settings, :map, default: %{"enabled" => false, "limit" => 6}
    field :content_tree, {:array, :map}, default: []
    field :published_content_tree, {:array, :map}, default: []
    field :published_settings, :map, default: %{}
    field :published_source_config, :map, default: %{}
    field :published_filters, :map, default: %{}
    field :published_loop_settings, :map, default: %{}
    field :published_at, :utc_datetime

    has_many :versions, SectionVersion

    timestamps()
  end

  @doc "Returns section mode options."
  @spec mode_options() :: [{String.t(), String.t()}]
  def mode_options do
    [
      {"Fixed", "fixed"},
      {"Collection", "collection"},
      {"Static", "static"},
      {"Dynamic", "dynamic"},
      {"Reference", "reference"}
    ]
  end

  @doc "Returns section status options."
  @spec status_options() :: [{String.t(), String.t()}]
  def status_options,
    do: [{"Draft", "draft"}, {"Published", "published"}, {"Archived", "archived"}]

  @doc "Builds a changeset for a reusable section."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(section, attrs) do
    section
    |> cast(attrs, [
      :name,
      :template_key,
      :group_label,
      :mode,
      :status,
      :settings,
      :source_config,
      :filters,
      :loop_settings,
      :content_tree,
      :published_content_tree,
      :published_settings,
      :published_source_config,
      :published_filters,
      :published_loop_settings,
      :published_at
    ])
    |> normalize_tree()
    |> normalize_maps()
    |> validate_required([:name, :template_key, :group_label, :mode, :status, :content_tree])
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:template_key, min: 2, max: 120)
    |> validate_length(:group_label, min: 2, max: 80)
    |> validate_inclusion(:mode, @modes)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:name, name: :sections_name_index)
  end

  defp normalize_tree(changeset) do
    changeset
    |> normalize_list(:content_tree)
    |> normalize_list(:published_content_tree)
  end

  defp normalize_maps(changeset) do
    changeset
    |> normalize_map(:settings)
    |> normalize_map(:source_config)
    |> normalize_map(:filters)
    |> normalize_map(:loop_settings, %{"enabled" => false, "limit" => 6})
    |> normalize_map(:published_settings)
    |> normalize_map(:published_source_config)
    |> normalize_map(:published_filters)
    |> normalize_map(:published_loop_settings)
  end

  defp normalize_list(changeset, field) do
    case get_field(changeset, field) do
      value when is_list(value) -> changeset
      _other -> put_change(changeset, field, [])
    end
  end

  defp normalize_map(changeset, field, default \\ %{}) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _other -> put_change(changeset, field, default)
    end
  end
end
