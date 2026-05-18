defmodule MangoCMS.Tenant.Media.MediaAsset do
  @moduledoc """
  Tenant-local metadata for a stored media file.

  File bytes live in the configured upload storage, while this schema keeps the
  searchable and reusable asset record inside the tenant database.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias MangoCMS.Tenant.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @kinds ~w(image video audio document asset)

  @type t :: %__MODULE__{}

  schema "media_assets" do
    field :original_filename, :string
    field :stored_filename, :string
    field :mime_type, :string
    field :file_ext, :string
    field :file_size, :integer, default: 0
    field :storage_path, :string
    field :public_url, :string
    field :alt_text, :string
    field :title, :string
    field :description, :string
    field :folder, :string
    field :kind, :string, default: "image"
    field :width, :integer
    field :height, :integer
    field :metadata, :map, default: %{}

    belongs_to :uploaded_by, User

    timestamps()
  end

  @doc "Builds a changeset for a media asset metadata record."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [
      :id,
      :original_filename,
      :stored_filename,
      :mime_type,
      :file_ext,
      :file_size,
      :storage_path,
      :public_url,
      :alt_text,
      :title,
      :description,
      :folder,
      :kind,
      :width,
      :height,
      :metadata,
      :uploaded_by_id
    ])
    |> normalize_map(:metadata)
    |> validate_required([
      :id,
      :original_filename,
      :stored_filename,
      :mime_type,
      :file_ext,
      :storage_path,
      :public_url,
      :kind
    ])
    |> validate_inclusion(:kind, @kinds)
    |> validate_number(:file_size, greater_than_or_equal_to: 0)
    |> validate_number(:width, greater_than: 0)
    |> validate_number(:height, greater_than: 0)
    |> validate_length(:original_filename, max: 255)
    |> validate_length(:stored_filename, max: 255)
    |> validate_length(:mime_type, max: 120)
    |> validate_length(:file_ext, max: 20)
    |> validate_length(:storage_path, max: 700)
    |> validate_length(:public_url, max: 700)
    |> validate_length(:alt_text, max: 255)
    |> validate_length(:title, max: 255)
    |> validate_length(:description, max: 500)
    |> validate_length(:folder, max: 160)
    |> foreign_key_constraint(:uploaded_by_id)
    |> unique_constraint(:public_url)
  end

  defp normalize_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _other -> put_change(changeset, field, %{})
    end
  end
end
