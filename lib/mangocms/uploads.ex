defmodule MangoCMS.Uploads do
  @moduledoc """
  Centralized local upload storage for platform and tenant-owned assets.

  Files are stored under `priv/static/uploads` so Phoenix can serve them through
  Plug.Static. Tenant and platform paths are separated to keep media ownership
  explicit even when the same upload pipeline is reused by different UIs.
  """

  alias MangoCMS.Platform.Tenant
  alias Phoenix.LiveView.UploadEntry

  @type scope :: :platform | {:tenant, Tenant.t()}
  @type upload_type :: String.t() | [String.t()]

  @doc "Stores a consumed LiveView upload entry and returns its public URL path."
  @spec store_live_upload!(UploadEntry.t(), map(), scope(), keyword()) :: String.t()
  def store_live_upload!(%UploadEntry{} = entry, %{path: source_path}, scope, opts \\ []) do
    type = Keyword.get(opts, :type, "images")
    filename = upload_filename(entry)
    directory = upload_directory(scope, type)

    File.mkdir_p!(directory)
    File.cp!(source_path, Path.join(directory, filename))

    public_path(scope, type, filename)
  end

  @doc "Returns the filesystem directory for a storage scope and type."
  @spec upload_directory(scope(), upload_type()) :: String.t()
  def upload_directory(scope, type \\ "images") do
    Path.join(
      [to_string(:code.priv_dir(:mangocms)), "static", "uploads"] ++
        scope_segments(scope) ++ upload_type_segments(type)
    )
  end

  @doc "Returns the public URL path for a stored upload."
  @spec public_path(scope(), upload_type(), String.t()) :: String.t()
  def public_path(scope, type, filename) do
    Path.join(["/uploads"] ++ scope_segments(scope) ++ upload_type_segments(type) ++ [filename])
  end

  defp scope_segments(:platform), do: ["platform"]
  defp scope_segments({:tenant, %Tenant{id: id}}), do: ["tenants", safe_path_segment(id)]

  defp upload_type_segments(type) when is_list(type) do
    Enum.map(type, &safe_path_segment/1)
  end

  defp upload_type_segments(type), do: [safe_path_segment(type)]

  defp upload_filename(%UploadEntry{} = entry) do
    extension =
      entry.client_name
      |> Path.extname()
      |> String.downcase()
      |> safe_extension()

    "#{Ecto.UUID.generate()}#{extension}"
  end

  defp safe_extension(extension)
       when extension in [".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg"],
       do: extension

  defp safe_extension(_extension), do: ".bin"

  defp safe_path_segment(value) when is_binary(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_-]+/, "-")
    |> String.trim("-")
    |> case do
      "" -> "asset"
      segment -> segment
    end
  end
end
