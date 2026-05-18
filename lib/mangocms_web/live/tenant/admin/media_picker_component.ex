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

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:tab, fn -> "library" end)
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
        {:noreply, socket}

      [] ->
        {:noreply, put_flash(socket, :error, "Choose a file before saving.")}

      [{:error, _changeset} | _rest] ->
        {:noreply, put_flash(socket, :error, "Could not save media asset.")}
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
                      :if={asset.kind == "image"}
                      src={asset.public_url}
                      alt={asset.alt_text || ""}
                      class="h-full w-full object-cover"
                    />
                    <div :if={asset.kind != "image"} class="grid h-full place-items-center">
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

            <div :if={@tab == "upload"} id={"#{@id}-upload"} class="grid gap-4">
              <div class="rounded-lg border border-dashed border-base-300 bg-base-200/40 p-6">
                <.live_file_input
                  upload={@uploads.media_asset}
                  class="file-input file-input-bordered w-full"
                />
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
                      <p class="text-base-content/60">{entry.progress}% uploaded</p>
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
                  type="button"
                  phx-click="upload_and_select"
                  phx-target={@myself}
                  class="btn btn-primary"
                >
                  Upload and select
                </button>
              </div>
            </div>
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
        max_file_size: 5_000_000,
        auto_upload: true
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
        max_file_size: 50_000_000,
        auto_upload: true
      )
    end
  end

  defp notify_parent(%{assigns: %{notify: %{module: module, id: id}}}, message) do
    send_update(module, id: id, media_picker_message: message)
  end

  defp notify_parent(_socket, message), do: send(self(), {__MODULE__, message})
end
