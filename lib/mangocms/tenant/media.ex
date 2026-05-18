defmodule MangoCMS.Tenant.Media do
  @moduledoc """
  Tenant-scoped media library.

  The media library stores files once under tenant-owned upload storage and
  keeps reusable metadata records in the tenant database.
  """

  import Ecto.Query

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.Media.MediaAsset
  alias MangoCMS.Tenant.RepoManager, as: TenantRepoManager
  alias MangoCMS.Uploads
  alias Phoenix.LiveView.UploadEntry

  @image_exts ~w(.jpg .jpeg .png .gif .webp .svg)
  @video_exts ~w(.mp4 .webm .mov)
  @audio_exts ~w(.mp3 .wav .ogg)
  @document_exts ~w(.pdf .doc .docx .xls .xlsx .csv .txt)
  @safe_exts @image_exts ++ @video_exts ++ @audio_exts ++ @document_exts

  @doc "Lists media assets for the tenant, newest first."
  @spec list_assets(Tenant.t(), keyword()) :: [MediaAsset.t()]
  def list_assets(%Tenant{} = tenant, opts \\ []) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      MediaAsset
      |> maybe_filter_kind(Keyword.get(opts, :kind))
      |> maybe_search(Keyword.get(opts, :query, ""))
      |> order_by([asset], desc: asset.inserted_at)
      |> limit(^limit_value(opts))
      |> repo.all()
    end)
  end

  @doc "Fetches one media asset by id."
  @spec get_asset!(Tenant.t(), String.t()) :: MediaAsset.t()
  def get_asset!(%Tenant{} = tenant, id) when is_binary(id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get!(MediaAsset, id)
    end)
  end

  @doc "Stores a consumed LiveView upload as a reusable tenant media asset."
  @spec create_asset_from_upload(Tenant.t(), UploadEntry.t(), map(), keyword()) ::
          {:ok, MediaAsset.t()} | {:error, Ecto.Changeset.t()}
  def create_asset_from_upload(%Tenant{} = tenant, %UploadEntry{} = entry, meta, opts \\ []) do
    asset_id = Ecto.UUID.generate()
    extension = entry.client_name |> Path.extname() |> String.downcase() |> safe_extension()
    stored_filename = "original#{extension}"
    folder = opts |> Keyword.get(:folder, "library") |> safe_folder()
    kind = Keyword.get(opts, :kind) || kind_from(entry.client_type, extension)
    type = ["media", asset_id]
    directory = Uploads.upload_directory({:tenant, tenant}, type)
    storage_path = Path.join(directory, stored_filename)
    public_url = Uploads.public_path({:tenant, tenant}, type, stored_filename)

    File.mkdir_p!(directory)
    File.cp!(meta.path, storage_path)

    attrs = %{
      "id" => asset_id,
      "original_filename" => entry.client_name,
      "stored_filename" => stored_filename,
      "mime_type" => entry.client_type || "application/octet-stream",
      "file_ext" => extension,
      "file_size" => file_size(storage_path),
      "storage_path" => storage_path,
      "public_url" => public_url,
      "title" => Keyword.get(opts, :title) || default_title(entry.client_name),
      "alt_text" => Keyword.get(opts, :alt_text),
      "description" => Keyword.get(opts, :description),
      "folder" => folder,
      "kind" => kind,
      "metadata" => Keyword.get(opts, :metadata, %{}),
      "uploaded_by_id" => Keyword.get(opts, :uploaded_by_id)
    }

    create_asset(tenant, attrs)
  end

  @doc "Creates a media asset metadata record."
  @spec create_asset(Tenant.t(), map()) :: {:ok, MediaAsset.t()} | {:error, Ecto.Changeset.t()}
  def create_asset(%Tenant{} = tenant, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %MediaAsset{}
      |> MediaAsset.changeset(attrs)
      |> repo.insert()
    end)
  end

  @doc "Returns an asset payload map suitable for JSON content fields."
  @spec asset_payload(MediaAsset.t()) :: map()
  def asset_payload(%MediaAsset{} = asset) do
    %{
      "asset_id" => asset.id,
      "url" => asset.public_url,
      "alt" => asset.alt_text || asset.title || asset.original_filename
    }
  end

  defp maybe_filter_kind(query, kind) when kind in ~w(image video audio document asset) do
    where(query, [asset], asset.kind == ^kind)
  end

  defp maybe_filter_kind(query, _kind), do: query

  defp maybe_search(query, query_text) when is_binary(query_text) do
    query_text = String.trim(query_text)

    if query_text == "" do
      query
    else
      pattern = "%#{query_text}%"

      where(
        query,
        [asset],
        like(asset.title, ^pattern) or like(asset.original_filename, ^pattern) or
          like(asset.alt_text, ^pattern)
      )
    end
  end

  defp maybe_search(query, _query_text), do: query

  defp limit_value(opts) do
    opts
    |> Keyword.get(:limit, 48)
    |> min(100)
    |> max(1)
  end

  defp safe_extension(extension) when extension in @safe_exts,
    do: extension

  defp safe_extension(_extension), do: ".bin"

  defp kind_from(mime_type, extension) do
    cond do
      is_binary(mime_type) and String.starts_with?(mime_type, "image/") -> "image"
      is_binary(mime_type) and String.starts_with?(mime_type, "video/") -> "video"
      is_binary(mime_type) and String.starts_with?(mime_type, "audio/") -> "audio"
      extension in @image_exts -> "image"
      extension in @video_exts -> "video"
      extension in @audio_exts -> "audio"
      extension in @document_exts -> "document"
      true -> "asset"
    end
  end

  defp file_size(path) do
    case File.stat(path) do
      {:ok, %{size: size}} -> size
      {:error, _reason} -> 0
    end
  end

  defp default_title(filename) do
    filename
    |> Path.basename(Path.extname(filename))
    |> String.replace(~r/[_-]+/, " ")
    |> String.trim()
  end

  defp safe_folder(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> "library"
      folder -> folder
    end
  end

  defp safe_folder(_value), do: "library"
end
