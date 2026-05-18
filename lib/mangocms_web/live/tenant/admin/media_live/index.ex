defmodule MangoCMSWeb.Tenant.Admin.MediaLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.Media
  alias MangoCMSWeb.AdminGuard
  alias MangoCMSWeb.Tenant.Admin.MediaPickerComponent

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_content) do
      {:ok, socket} ->
        {:ok,
         socket
         |> assign(:query, "")
         |> assign(:media_picker, nil)
         |> assign_assets()}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("search_media", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:query, query)
     |> assign_assets()}
  end

  def handle_event("open_media_picker", _params, socket) do
    {:noreply, assign(socket, :media_picker, %{source: "media_index"})}
  end

  @impl true
  def handle_info({MediaPickerComponent, {:closed, _context}}, socket) do
    {:noreply, assign(socket, :media_picker, nil)}
  end

  def handle_info({MediaPickerComponent, {:selected, _context, _asset}}, socket) do
    {:noreply,
     socket
     |> assign(:media_picker, nil)
     |> assign_assets()
     |> put_flash(:info, "Media asset ready.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title="Media library"
      subtitle="Reusable tenant files for logos, collection images, pages, and sections."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:media}
    >
      <:actions>
        <button
          id="open-media-picker-button"
          type="button"
          phx-click="open_media_picker"
          class="btn btn-primary"
        >
          <.icon name="hero-arrow-up-tray" class="size-4" /> Upload or select
        </button>
      </:actions>

      <section class="rounded-lg border border-base-300 bg-base-100 text-base-content shadow-sm">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-base-300 p-4">
          <div>
            <h2 class="font-semibold">Tenant files</h2>
            <p class="mt-1 text-sm text-base-content/60">
              {@asset_count}/{max_media_files(@current_tenant)} files · {format_bytes(@asset_size)} used of {format_bytes(
                max_storage_bytes(@current_tenant)
              )}
            </p>
          </div>

          <form phx-change="search_media" class="contents">
            <label class="input input-bordered input-sm flex min-w-72 items-center gap-2 rounded-full">
              <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
              <input
                id="media-search"
                type="search"
                name="q"
                value={@query}
                phx-debounce="300"
                placeholder="Search media"
                class="grow"
              />
            </label>
          </form>
        </div>

        <div id="media-assets-grid" class="grid gap-4 p-5 sm:grid-cols-2 lg:grid-cols-4">
          <article
            :for={asset <- @assets}
            id={"media-index-asset-#{asset.id}"}
            class="rounded-lg border border-base-300 bg-base-100 p-3 shadow-sm"
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
            <p class="mt-3 truncate text-sm font-semibold">
              {asset.title || asset.original_filename}
            </p>
            <p class="mt-1 truncate text-xs text-base-content/60">{asset.public_url}</p>
            <p class="mt-2 text-xs text-base-content/50">{format_bytes(asset.file_size)}</p>
          </article>

          <div
            :if={@assets == []}
            class="col-span-full rounded-lg border border-dashed border-base-300 p-8 text-center text-sm text-base-content/60"
          >
            No media assets match this search.
          </div>
        </div>
      </section>

      <.live_component
        :if={@media_picker}
        module={MediaPickerComponent}
        id="media-library-picker"
        tenant={@current_tenant}
        current_user={@current_user}
        kind="asset"
        context={@media_picker}
      />
    </Layouts.tenant_admin>
    """
  end

  defp assign_assets(socket) do
    tenant = socket.assigns.current_tenant

    socket
    |> assign(:assets, Media.list_assets(tenant, query: socket.assigns.query, limit: 100))
    |> assign(:asset_count, Media.count_assets(tenant))
    |> assign(:asset_size, Media.total_asset_size(tenant))
  end

  defp max_media_files(%{plan: %{max_media_files: max}}) when is_integer(max) and max > 0,
    do: max

  defp max_media_files(_tenant), do: 100

  defp max_storage_bytes(%{plan: %{max_storage_mb: max}}) when is_integer(max) and max > 0,
    do: max * 1_024 * 1_024

  defp max_storage_bytes(_tenant), do: 500 * 1_024 * 1_024

  defp format_bytes(bytes) when is_integer(bytes) and bytes >= 1_048_576 do
    "#{Float.round(bytes / 1_048_576, 1)} MB"
  end

  defp format_bytes(bytes) when is_integer(bytes) and bytes >= 1024 do
    "#{Float.round(bytes / 1024, 1)} KB"
  end

  defp format_bytes(bytes) when is_integer(bytes), do: "#{bytes} B"
  defp format_bytes(_bytes), do: "0 B"

  defp image_asset?(asset) do
    asset.kind == "image" or String.starts_with?(asset.mime_type || "", "image/") or
      asset.file_ext in ~w(.jpg .jpeg .png .gif .webp .svg)
  end
end
