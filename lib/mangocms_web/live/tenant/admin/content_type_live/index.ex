defmodule MangoCMSWeb.Tenant.Admin.ContentTypeLive.Index do
  use MangoCMSWeb, :live_view

  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.ContentEngine.ContentType
  alias MangoCMSWeb.AdminGuard

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_content) do
      {:ok, socket} ->
        tenant = socket.assigns.current_tenant
        collections = ContentEngine.list_content_types(tenant)

        {:ok,
         socket
         |> assign(:collection_query, "")
         |> assign(:collections, collections)
         |> assign(:collection_entry_counts, ContentEngine.content_type_entry_counts(tenant))
         |> stream(:content_types, collections)}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign(:collection_base_path, collection_base_path(url))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit collection")
    |> assign(:content_type, ContentEngine.get_content_type!(socket.assigns.current_tenant, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create collection")
    |> assign(:content_type, %ContentType{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Collections")
    |> assign(:content_type, nil)
  end

  @impl true
  def handle_info(
        {MangoCMSWeb.Tenant.Admin.ContentTypeLive.FormComponent, {:saved, content_type}},
        socket
      ) do
    collections = ContentEngine.list_content_types(socket.assigns.current_tenant)

    {:noreply,
     socket
     |> assign(:collections, collections)
     |> assign(
       :collection_entry_counts,
       ContentEngine.content_type_entry_counts(socket.assigns.current_tenant)
     )
     |> stream_insert(:content_types, content_type)}
  end

  @impl true
  def handle_event("search_collections", %{"q" => query}, socket) do
    {:noreply, assign(socket, :collection_query, query)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    content_type = ContentEngine.get_content_type!(tenant, id)
    {:ok, _content_type} = ContentEngine.delete_content_type(tenant, content_type)
    collections = ContentEngine.list_content_types(tenant)

    {:noreply,
     socket
     |> assign(:collections, collections)
     |> assign(:collection_entry_counts, ContentEngine.content_type_entry_counts(tenant))
     |> stream_delete(:content_types, content_type)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title="CMS"
      subtitle="Store and manage content to display anywhere on your site."
      current_user={@current_user}
      current_tenant={@current_tenant}
      current_tenant_settings={@current_tenant_settings}
      active={:content}
    >
      <:actions>
        <div class="dropdown dropdown-end">
          <button id="collection-more-actions-button" type="button" tabindex="0" class="btn btn-ghost">
            More Actions <.icon name="hero-chevron-down" class="size-4" />
          </button>
          <ul
            tabindex="0"
            class="menu dropdown-content z-20 mt-2 w-64 rounded-lg border border-base-300 bg-base-100 p-2 shadow-xl"
          >
            <li><a>Create folder</a></li>
            <li><a>Backups</a></li>
            <li><a>Advanced Settings</a></li>
            <li class="menu-title">Support</li>
            <li><a>Watch a video course</a></li>
            <li><a>Help center</a></li>
            <li><a>Submit feedback</a></li>
            <li><a>Ask the community</a></li>
          </ul>
        </div>
        <.button id="new-content-type-button" patch={"#{@collection_base_path}/new"} variant="primary">
          <.icon name="hero-plus" class="size-4" /> Create Collection
        </.button>
      </:actions>

      <.live_component
        :if={@live_action in [:new, :edit]}
        module={MangoCMSWeb.Tenant.Admin.ContentTypeLive.FormComponent}
        id={@content_type.id || :new}
        title={@page_title}
        action={@live_action}
        tenant={@current_tenant}
        content_type={@content_type}
        patch={@collection_base_path}
      />

      <div class="mt-8 max-w-xl">
        <label class="input input-bordered flex items-center gap-2">
          <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
          <input
            id="collection-search"
            type="search"
            name="q"
            value={@collection_query}
            phx-keyup="search_collections"
            placeholder="Search collections..."
            class="grow"
          />
        </label>
      </div>

      <section id="collections-directory" class="mt-6 space-y-6">
        <.collection_group
          id="your-collections"
          title="Your Collections"
          description={
            quota_text(
              filtered_collections(@collections, @collection_query, false),
              @collection_entry_counts
            )
          }
          collections={filtered_collections(@collections, @collection_query, false)}
          entry_counts={@collection_entry_counts}
          locked={false}
          base_path={@collection_base_path}
        />

        <.collection_group
          id="mango-form-collections"
          title="Mango Form Collections"
          description="Collections automatically added whenever a Mango Form is added to a site."
          collections={filtered_collections(@collections, @collection_query, true)}
          entry_counts={@collection_entry_counts}
          locked={true}
          base_path={@collection_base_path}
        />
      </section>
    </Layouts.tenant_admin>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :collections, :list, required: true
  attr :entry_counts, :map, required: true
  attr :locked, :boolean, default: false
  attr :base_path, :string, required: true

  defp collection_group(assigns) do
    ~H"""
    <details id={@id} open class="rounded-lg border border-base-300 bg-base-100">
      <summary class="cursor-pointer border-b border-base-300 px-5 py-4">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="font-semibold">{@title} ({length(@collections)})</h2>
            <p class="mt-1 text-sm text-base-content/60">{@description}</p>
          </div>
          <.icon name="hero-chevron-up" class="size-4 text-base-content/50" />
        </div>
      </summary>

      <div class="grid gap-4 p-5 sm:grid-cols-2 xl:grid-cols-4">
        <.collection_card
          :for={collection <- @collections}
          collection={collection}
          item_count={Map.get(@entry_counts, collection.id, 0)}
          locked={@locked || collection.archetype == "form"}
          base_path={@base_path}
        />
        <div
          :if={@collections == []}
          class="rounded-lg border border-dashed border-base-300 p-6 text-sm text-base-content/60"
        >
          No collections match this group.
        </div>
      </div>
    </details>
    """
  end

  attr :collection, :map, required: true
  attr :item_count, :integer, required: true
  attr :locked, :boolean, default: false
  attr :base_path, :string, required: true

  defp collection_card(assigns) do
    ~H"""
    <article
      id={"collection-card-#{@collection.id}"}
      class="group relative rounded-lg border border-base-300 bg-base-100 p-5 shadow-sm transition hover:border-primary hover:shadow-md"
    >
      <.link
        id={"open-collection-#{@collection.id}"}
        navigate={"#{@base_path}/#{@collection.id}"}
        class="absolute inset-0 z-0 rounded-lg"
        aria-label={"Open #{@collection.name}"}
      >
        <span class="sr-only">Open {@collection.name}</span>
      </.link>
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0">
          <p class="truncate text-xs font-bold uppercase tracking-wide text-base-content/60">
            {@collection.name}
          </p>
          <p class="mt-6 text-sm text-base-content/60">
            {@item_count} {ngettext("item", "items", @item_count)}
          </p>
        </div>

        <div class="dropdown dropdown-end relative z-10">
          <button
            id={"collection-actions-#{@collection.id}"}
            type="button"
            tabindex="0"
            class="btn btn-ghost btn-xs btn-circle"
          >
            <.icon name="hero-ellipsis-horizontal" class="size-4" />
          </button>
          <ul
            tabindex="0"
            class="menu dropdown-content z-20 mt-2 w-44 rounded-lg border border-base-300 bg-base-100 p-2 shadow-xl"
          >
            <li><.link navigate={"#{@base_path}/#{@collection.id}"}>Open</.link></li>
            <li>
              <.link
                id={"edit-content-type-#{@collection.id}"}
                patch={"#{@base_path}/#{@collection.id}/edit"}
              >
                Edit
              </.link>
            </li>
            <li>
              <button
                id={"delete-content-type-#{@collection.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={@collection.id}
                disabled={@locked}
                data-confirm="Delete this collection and all items?"
              >
                Delete
              </button>
            </li>
          </ul>
        </div>
      </div>
      <span :if={@locked} class="badge badge-ghost absolute right-5 bottom-5 z-10">
        <.icon name="hero-lock-closed" class="size-3" /> Locked
      </span>
    </article>
    """
  end

  defp filtered_collections(collections, query, form?) do
    query = query |> to_string() |> String.downcase()

    collections
    |> Enum.filter(fn collection -> collection.archetype == "form" == form? end)
    |> Enum.filter(fn collection ->
      query == "" or String.contains?(String.downcase(collection.name), query) or
        String.contains?(String.downcase(collection.slug), query)
    end)
  end

  defp quota_text(collections, entry_counts) do
    count =
      Enum.reduce(collections, 0, fn collection, acc ->
        acc + Map.get(entry_counts, collection.id, 0)
      end)

    "You have #{count}/1,500 items. Need more? Upgrade your site."
  end

  defp collection_base_path(url) when is_binary(url) do
    if String.contains?(url, "/admin/collections"),
      do: "/admin/collections",
      else: "/admin/collections"
  end
end
