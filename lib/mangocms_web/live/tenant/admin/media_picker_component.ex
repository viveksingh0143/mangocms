defmodule MangoCMSWeb.Tenant.Admin.MediaPickerComponent do
  @moduledoc """
  Shared tenant media library picker.

  Callers pass a context map that is echoed back when an existing or newly
  uploaded media asset is selected.
  """

  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.Media

  @impl true
  def update(assigns, socket) do
    tenant = assigns.tenant
    current_count = Media.count_assets(tenant)
    current_size = Media.total_asset_size(tenant)

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:tab, fn -> "library" end)
      |> assign(:current_count, current_count)
      |> assign(:current_size, current_size)
      |> assign(:max_media_files, max_media_files(tenant))
      |> assign(:max_storage_bytes, max_storage_bytes(tenant))
      |> assign(:max_upload_bytes, max_upload_bytes(tenant, current_size))
      |> assign(:upload_notice, nil)
      |> assign(:upload_form, to_form(%{}, as: :media_upload))
      |> assign(
        :assets,
        Media.list_assets(tenant, kind: assigns.kind, query: socket.assigns[:query] || "")
      )
      |> maybe_allow_upload(assigns.kind)

    {:ok, socket}
  end

  @impl true
  def handle_event("close", _params, socket) do
    notify_parent(socket, {:closed, socket.assigns.context})
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) when tab in ~w(library upload) do
    {:noreply, assign(socket, :tab, tab)}
  end

  def handle_event("validate_upload", _params, socket) do
    {:noreply, assign(socket, :upload_notice, nil)}
  end

  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(
       :assets,
       Media.list_assets(socket.assigns.tenant, kind: socket.assigns.kind, query: query)
     )}
  end

  def handle_event("select_asset", %{"id" => id}, socket) do
    asset = Media.get_asset!(socket.assigns.tenant, id)
    notify_parent(socket, {:selected, socket.assigns.context, asset})
    {:noreply, socket}
  end

  def handle_event("upload_and_select", _params, socket) do
    cond do
      upload_limit_reached?(socket) ->
        {:noreply,
         socket
         |> assign(:upload_notice, {:error, "Media limit reached for this tenant plan."})
         |> put_flash(:error, "Media limit reached for this tenant plan.")}

      upload_in_progress?(socket) ->
        {:noreply, assign(socket, :upload_notice, {:info, "Upload is still in progress."})}

      upload_entries(socket) == [] ->
        {:noreply, assign(socket, :upload_notice, {:error, "Choose a file before saving."})}

      true ->
        upload_and_select(socket)
    end
  end

  defp upload_and_select(socket) do
    uploaded_assets =
      consume_uploaded_entries(socket, :media_asset, fn meta, entry ->
        case Media.create_asset_from_upload(socket.assigns.tenant, entry, meta,
               kind: socket.assigns.kind,
               folder: "library",
               uploaded_by_id: socket.assigns.current_user && socket.assigns.current_user.id
             ) do
          {:ok, asset} -> {:ok, asset}
          {:error, changeset} -> {:ok, {:error, changeset}}
        end
      end)

    case uploaded_assets do
      [%Media.MediaAsset{} = asset | _rest] ->
        notify_parent(socket, {:selected, socket.assigns.context, asset})
        {:noreply, put_flash(socket, :info, "Media asset uploaded successfully.")}

      [] ->
        {:noreply, assign(socket, :upload_notice, {:error, "Choose a file before saving."})}

      [{:error, _changeset} | _rest] ->
        {:noreply,
         socket
         |> assign(:upload_notice, {:error, "Could not save media asset."})
         |> put_flash(:error, "Could not save media asset.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <dialog id={@id} open class="modal modal-open">
      <div class="modal-box max-w-5xl p-0">
        <div class="flex items-start justify-between gap-4 border-b border-base-300 p-5">
          <div>
            <h3 class="text-lg font-semibold">Media library</h3>
            <p class="mt-1 text-sm text-base-content/60">
              Select an existing tenant asset or upload a new one.
            </p>
            <p class="mt-2 text-xs text-base-content/50">
              {@current_count}/{@max_media_files} files · {format_bytes(@current_size)} used of {format_bytes(
                @max_storage_bytes
              )}
            </p>
          </div>
          <button type="button" phx-click="close" phx-target={@myself} class="btn btn-ghost btn-sm">
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>

        <div class="grid min-h-[32rem] md:grid-cols-[16rem_1fr]">
          <aside class="border-b border-base-300 bg-base-200/40 p-4 md:border-r md:border-b-0">
            <div class="tabs tabs-boxed grid grid-cols-2">
              <button
                type="button"
                phx-click="set_tab"
                phx-value-tab="library"
                phx-target={@myself}
                class={["tab", @tab == "library" && "tab-active"]}
              >
                Library
              </button>
              <button
                type="button"
                phx-click="set_tab"
                phx-value-tab="upload"
                phx-target={@myself}
                class={["tab", @tab == "upload" && "tab-active"]}
              >
                Upload
              </button>
            </div>

            <form phx-change="search" phx-target={@myself} class="mt-4">
              <label class="input input-bordered input-sm flex items-center gap-2">
                <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
                <input
                  id={"#{@id}-search"}
                  type="search"
                  name="q"
                  value={@query}
                  phx-debounce="300"
                  placeholder="Search media"
                  class="grow"
                />
              </label>
            </form>
          </aside>

          <section class="min-h-0 p-5">
            <div :if={@tab == "library"} id={"#{@id}-library"} class="h-[30rem] overflow-y-auto pr-1">
              <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                <button
                  :for={asset <- @assets}
                  id={"media-asset-#{asset.id}"}
                  type="button"
                  phx-click="select_asset"
                  phx-value-id={asset.id}
                  phx-target={@myself}
                  class="group rounded-lg border border-base-300 bg-base-100 p-2 text-left transition hover:border-primary hover:shadow-md"
                >
                  <div class="aspect-video overflow-hidden rounded-md bg-base-200">
                    <img
                      :if={image_asset?(asset)}
                      src={asset.public_url}
                      alt={asset.alt_text || ""}
                      class="h-full w-full object-cover"
                    />
                    <div :if={!image_asset?(asset)} class="grid h-full place-items-center">
                      <.icon name="hero-document" class="size-8 text-base-content/40" />
                    </div>
                  </div>
                  <p class="mt-2 truncate text-sm font-medium">
                    {asset.title || asset.original_filename}
                  </p>
                  <p class="truncate text-xs text-base-content/50">{asset.original_filename}</p>
                </button>

                <div
                  :if={@assets == []}
                  class="col-span-full rounded-lg border border-dashed border-base-300 p-8 text-center text-sm text-base-content/60"
                >
                  No media assets yet.
                </div>
              </div>
            </div>

            <.form
              :if={@tab == "upload"}
              for={@upload_form}
              id={"#{@id}-upload"}
              phx-change="validate_upload"
              phx-submit="upload_and_select"
              phx-target={@myself}
              class="grid gap-4"
            >
              <div
                :if={upload_limit_reached?(@current_count, @max_media_files)}
                class="alert alert-error"
              >
                <.icon name="hero-exclamation-triangle" class="size-5" />
                <span>Your plan media file limit has been reached.</span>
              </div>

              <div :if={@upload_notice} class={notice_class(@upload_notice)}>
                <.icon name={notice_icon(@upload_notice)} class="size-5" />
                <span>{elem(@upload_notice, 1)}</span>
              </div>

              <div :if={@uploads.media_asset.errors != []} class="alert alert-error">
                <.icon name="hero-exclamation-triangle" class="size-5" />
                <div>
                  <p :for={error <- @uploads.media_asset.errors}>
                    {upload_error(error, @max_upload_bytes)}
                  </p>
                </div>
              </div>

              <div class="rounded-lg border border-dashed border-base-300 bg-base-200/40 p-6">
                <.live_file_input
                  upload={@uploads.media_asset}
                  disabled={upload_limit_reached?(@current_count, @max_media_files)}
                  class="file-input file-input-bordered w-full"
                />
                <p class="mt-2 text-xs text-base-content/60">
                  Maximum file size: {format_bytes(@max_upload_bytes)}.
                </p>
                <div class="mt-4 grid gap-2">
                  <div
                    :for={entry <- @uploads.media_asset.entries}
                    class="flex items-center gap-3 rounded-md border border-base-300 bg-base-100 p-3"
                  >
                    <.live_img_preview
                      :if={String.starts_with?(entry.client_type || "", "image/")}
                      entry={entry}
                      class="size-14 rounded object-cover"
                    />
                    <div class="min-w-0 text-sm">
                      <p class="truncate font-medium">{entry.client_name}</p>
                      <p class="text-base-content/60">
                        <span :if={entry.done?}>Uploaded</span>
                        <span :if={!entry.done? and entry.progress == 0}>Ready to upload</span>
                        <span :if={!entry.done? and entry.progress > 0}>
                          Uploading {entry.progress}%
                        </span>
                      </p>
                      <progress
                        class="progress progress-primary mt-2 w-full"
                        value={entry.progress}
                        max="100"
                      >
                      </progress>
                    </div>
                  </div>
                </div>
              </div>

              <div class="flex justify-end gap-2">
                <button
                  type="button"
                  phx-click="set_tab"
                  phx-value-tab="library"
                  phx-target={@myself}
                  class="btn btn-ghost"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={
                    upload_limit_reached?(@current_count, @max_media_files) or
                      @uploads.media_asset.errors != [] or
                      @uploads.media_asset.entries == []
                  }
                  class="btn btn-primary phx-submit-loading:btn-disabled"
                >
                  <.icon
                    name="hero-arrow-up-tray"
                    class="size-4 phx-submit-loading:animate-spin"
                  /> Upload
                </button>
              </div>
            </.form>
          </section>
        </div>
      </div>

      <form method="dialog" class="modal-backdrop">
        <button type="button" phx-click="close" phx-target={@myself}>close</button>
      </form>
    </dialog>
    """
  end

  defp maybe_allow_upload(socket, "image") do
    if Map.has_key?(socket.assigns[:uploads] || %{}, :media_asset) do
      socket
    else
      allow_upload(socket, :media_asset,
        accept: ~w(.jpg .jpeg .png .gif .webp .svg),
        max_entries: 1,
        max_file_size: socket.assigns.max_upload_bytes,
        auto_upload: false
      )
    end
  end

  defp maybe_allow_upload(socket, _kind) do
    if Map.has_key?(socket.assigns[:uploads] || %{}, :media_asset) do
      socket
    else
      allow_upload(socket, :media_asset,
        accept: ~w(.jpg .jpeg .png .gif .webp .svg .pdf .mp4 .webm .mov),
        max_entries: 1,
        max_file_size: socket.assigns.max_upload_bytes,
        auto_upload: false
      )
    end
  end

  defp upload_entries(socket), do: socket.assigns.uploads.media_asset.entries

  defp upload_in_progress?(%{assigns: _assigns} = socket),
    do: upload_in_progress?(upload_entries(socket))

  defp upload_in_progress?(entries), do: Enum.any?(entries, &(!&1.done?))

  defp upload_limit_reached?(socket) do
    upload_limit_reached?(socket.assigns.current_count, socket.assigns.max_media_files)
  end

  defp upload_limit_reached?(current_count, max_media_files), do: current_count >= max_media_files

  defp max_media_files(%{plan: %{max_media_files: max}}) when is_integer(max) and max > 0,
    do: max

  defp max_media_files(_tenant), do: 100

  defp max_storage_bytes(%{plan: %{max_storage_mb: max}}) when is_integer(max) and max > 0,
    do: max * 1_024 * 1_024

  defp max_storage_bytes(_tenant), do: 500 * 1_024 * 1_024

  defp max_upload_bytes(tenant, current_size) do
    max_single_upload =
      case tenant do
        %{plan: %{max_storage_mb: max}} when is_integer(max) and max > 0 ->
          min(max * 1_024 * 1_024, 50_000_000)

        _tenant ->
          50_000_000
      end

    remaining = max(max_storage_bytes(tenant) - current_size, 1)
    min(max_single_upload, remaining)
  end

  defp format_bytes(bytes) when is_integer(bytes) and bytes >= 1_048_576 do
    "#{Float.round(bytes / 1_048_576, 1)} MB"
  end

  defp format_bytes(bytes) when is_integer(bytes) and bytes >= 1024 do
    "#{Float.round(bytes / 1024, 1)} KB"
  end

  defp format_bytes(bytes) when is_integer(bytes), do: "#{bytes} B"
  defp format_bytes(_bytes), do: "0 B"

  defp upload_error(:too_large, max_upload_bytes),
    do: "File is too large. Maximum allowed size is #{format_bytes(max_upload_bytes)}."

  defp upload_error(:too_many_files, _max_upload_bytes), do: "Select one file at a time."
  defp upload_error(:not_accepted, _max_upload_bytes), do: "This file type is not accepted."
  defp upload_error(error, _max_upload_bytes), do: "Upload failed: #{inspect(error)}"

  defp image_asset?(asset) do
    asset.kind == "image" or String.starts_with?(asset.mime_type || "", "image/") or
      asset.file_ext in ~w(.jpg .jpeg .png .gif .webp .svg)
  end

  defp notice_class({:error, _message}), do: "alert alert-error"
  defp notice_class({:info, _message}), do: "alert alert-info"
  defp notice_class({_level, _message}), do: "alert alert-success"

  defp notice_icon({:error, _message}), do: "hero-exclamation-triangle"
  defp notice_icon({:info, _message}), do: "hero-arrow-path"
  defp notice_icon({_level, _message}), do: "hero-check-circle"

  defp notify_parent(%{assigns: %{notify: %{module: module, id: id}}}, message) do
    send_update(module, id: id, media_picker_message: message)
  end

  defp notify_parent(_socket, message), do: send(self(), {__MODULE__, message})
end
