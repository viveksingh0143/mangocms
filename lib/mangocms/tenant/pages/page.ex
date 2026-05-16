defmodule MangoCMS.Tenant.Pages.Page do
  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Pages.PageSection

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @types ~w(page post landing)
  @statuses ~w(draft published archived)

  @type t :: %__MODULE__{}

  schema "pages" do
    field :title, :string
    field :slug, :string
    field :type, :string, default: "page"
    field :status, :string, default: "draft"
    field :seo, :map, default: %{}
    field :published_at, :utc_datetime
    field :content_tree, {:array, :map}, default: []
    field :content_tree_version, :integer, default: 1

    has_many :sections, PageSection
    has_many :versions, MangoCMS.Tenant.Pages.PageVersion

    timestamps()
  end

  def type_options, do: Enum.map(@types, &{label(&1), &1})
  def status_options, do: Enum.map(@statuses, &{label(&1), &1})

  def changeset(page, attrs) do
    page
    |> cast(attrs, [:title, :slug, :type, :status, :seo, :published_at, :content_tree])
    |> normalize_map(:seo)
    |> normalize_tree()
    |> maybe_put_slug()
    |> normalize_change(:slug, &slugify/1)
    |> maybe_put_published_at()
    |> validate_required([:title, :slug, :type, :status, :seo, :content_tree])
    |> validate_length(:title, min: 2, max: 160)
    |> validate_length(:slug, min: 1, max: 160)
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/,
      message: "only lowercase letters, numbers, underscores and hyphens"
    )
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:slug, name: :pages_slug_index)
  end

  def tree_changeset(page, attrs) do
    page
    |> cast(attrs, [:title, :slug, :type, :status, :seo, :published_at, :content_tree])
    |> normalize_map(:seo)
    |> normalize_tree()
    |> maybe_put_slug()
    |> normalize_change(:slug, &slugify/1)
    |> maybe_put_published_at()
    |> validate_required([:title, :slug, :type, :status, :seo, :content_tree])
    |> validate_length(:title, min: 2, max: 160)
    |> validate_length(:slug, min: 1, max: 160)
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/,
      message: "only lowercase letters, numbers, underscores and hyphens"
    )
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:content_tree_version)
    |> unique_constraint(:slug, name: :pages_slug_index)
  end

  defp normalize_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _other -> put_change(changeset, field, %{})
    end
  end

  defp normalize_tree(changeset) do
    case get_field(changeset, :content_tree) do
      value when is_list(value) -> changeset
      _other -> put_change(changeset, :content_tree, [])
    end
  end

  defp maybe_put_slug(changeset) do
    slug = get_field(changeset, :slug)
    title = get_field(changeset, :title)

    if blank?(slug) and is_binary(title) do
      put_change(changeset, :slug, slugify(title))
    else
      changeset
    end
  end

  defp maybe_put_published_at(changeset) do
    if get_field(changeset, :status) == "published" and
         is_nil(get_field(changeset, :published_at)) do
      put_change(changeset, :published_at, DateTime.utc_now(:second))
    else
      changeset
    end
  end

  defp normalize_change(changeset, field, normalizer) do
    case get_change(changeset, field) do
      value when is_binary(value) -> put_change(changeset, field, normalizer.(value))
      _other -> changeset
    end
  end

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9_-]+/, "-")
    |> String.trim("-")
  end

  defp blank?(value), do: value in [nil, ""]

  defp label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
