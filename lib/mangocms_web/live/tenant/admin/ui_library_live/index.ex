defmodule MangoCMSWeb.Tenant.Admin.UILibraryLive.Index do
  @moduledoc "Component UI Library — browse, filter and live-edit every builder manifest."

  use MangoCMSWeb, :live_view

  alias MangoCMSWeb.AdminGuard
  alias MangoCMSWeb.Builder.Inspector
  alias MangoCMSWeb.Builder.Registry
  alias MangoCMSWeb.Builder.Renderer

  @all_group "All"

  # ── Lifecycle ─────────────────────────────────────────────────────────────────

  @impl true
  def mount(_params, _session, socket) do
    case AdminGuard.authorize_tenant(socket, :manage_pages) do
      {:ok, socket} ->
        manifests = Registry.all()
        groups = [@all_group | manifests |> Enum.map(& &1.group) |> Enum.uniq() |> Enum.sort()]

        {:ok,
         socket
         |> assign(:manifests, manifests)
         |> assign(:groups, groups)
         |> assign(:search, "")
         |> assign(:active_group, @all_group)
         |> assign(:selected_manifest, nil)
         |> assign(:selected_variant, nil)
         |> assign(:preview_node, nil)
         |> assign(:preview_width, "full")
         |> assign(:show_node_json, false)}

      {:redirect, socket} ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"name" => name}, _url, socket) do
    case Registry.get(name) do
      nil ->
        {:noreply, push_patch(socket, to: ~p"/admin/ui-library")}

      manifest ->
        variant_id = manifest.default_variant
        preview_node = Registry.default_node(name, variant_id)

        {:noreply,
         socket
         |> assign(:page_title, manifest.label)
         |> assign(:selected_manifest, manifest)
         |> assign(:selected_variant, variant_id)
         |> assign(:preview_node, preview_node)
         |> assign(:show_node_json, false)}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "UI Library")
     |> assign(:selected_manifest, nil)
     |> assign(:selected_variant, nil)
     |> assign(:preview_node, nil)}
  end

  # ── Events ────────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, assign(socket, :search, q)}
  end

  def handle_event("filter_group", %{"group" => group}, socket) do
    {:noreply, assign(socket, :active_group, group)}
  end

  def handle_event("select_variant", %{"variant" => variant_id}, socket) do
    manifest = socket.assigns.selected_manifest
    variant = Registry.variant(manifest, variant_id)

    new_props =
      Map.merge(
        manifest.default_props,
        Map.get(variant || %{}, :default_props, %{})
      )

    new_node =
      socket.assigns.preview_node
      |> Map.put("props", new_props)
      |> Map.put("variant", variant_id)

    {:noreply,
     socket
     |> assign(:selected_variant, variant_id)
     |> assign(:preview_node, new_node)}
  end

  def handle_event("update_props", params, socket) do
    new_node = apply_prop_changes(socket.assigns.preview_node, params)
    {:noreply, assign(socket, :preview_node, new_node)}
  end

  def handle_event("set_preview_width", %{"width" => width}, socket) do
    {:noreply, assign(socket, :preview_width, width)}
  end

  def handle_event("toggle_node_json", _params, socket) do
    {:noreply, update(socket, :show_node_json, &(!&1))}
  end

  # ── Render ────────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    assigns =
      assign(
        assigns,
        :filtered_manifests,
        filtered_manifests(assigns.manifests, assigns.search, assigns.active_group)
      )

    ~H"""
    <Layouts.tenant_admin
      flash={@flash}
      title={@page_title}
      current_user={@current_user}
      current_tenant={@current_tenant}
      active={:ui_library}
    >
      <:actions :if={@live_action == :show}>
        <.link patch={~p"/admin/ui-library"} class="btn btn-ghost btn-sm gap-1">
          <.icon name="hero-arrow-left" class="size-4" /> All components
        </.link>
      </:actions>

      <div :if={@live_action == :index} class="space-y-6">
        <.browser_toolbar
          groups={@groups}
          active_group={@active_group}
          search={@search}
          manifests={@manifests}
        />
        <.component_grid manifests={@filtered_manifests} />
      </div>

      <.component_detail
        :if={@live_action == :show && @selected_manifest}
        manifest={@selected_manifest}
        selected_variant={@selected_variant}
        preview_node={@preview_node}
        preview_width={@preview_width}
        show_node_json={@show_node_json}
      />
    </Layouts.tenant_admin>
    """
  end

  # ── Sub-components ────────────────────────────────────────────────────────────

  attr :groups, :list, required: true
  attr :active_group, :string, required: true
  attr :search, :string, required: true
  attr :manifests, :list, required: true

  defp browser_toolbar(assigns) do
    ~H"""
    <div class="space-y-3">
      <form phx-change="search" phx-submit="search" class="relative">
        <.icon
          name="hero-magnifying-glass"
          class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-base-content/40 pointer-events-none"
        />
        <input
          type="search"
          name="q"
          value={@search}
          placeholder="Search components…"
          phx-debounce="150"
          class="input input-bordered w-full pl-10"
        />
      </form>

      <div class="flex flex-wrap gap-2">
        <button
          :for={group <- @groups}
          phx-click="filter_group"
          phx-value-group={group}
          class={[
            "btn btn-sm gap-1",
            if(@active_group == group,
              do: "btn-primary",
              else: "btn-ghost border border-base-300"
            )
          ]}
        >
          {group}
          <span class="badge badge-sm badge-ghost">{count_in_group(@manifests, group)}</span>
        </button>
      </div>
    </div>
    """
  end

  attr :manifests, :list, required: true

  defp component_grid(assigns) do
    ~H"""
    <div :if={@manifests == []} class="py-24 text-center text-base-content/40">
      <.icon name="hero-cube" class="mx-auto mb-3 size-10 opacity-40" />
      <p>No components match your search.</p>
    </div>

    <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-4">
      <.link
        :for={manifest <- @manifests}
        patch={~p"/admin/ui-library/#{manifest.name}"}
        class="card border border-base-300 bg-base-100 hover:border-primary hover:shadow-md transition-all group overflow-hidden"
      >
        <div class="bg-base-200 h-36 flex items-center justify-center overflow-hidden p-4">
          <div class="pointer-events-none scale-75 origin-center w-full">
            <Renderer.node
              node={Registry.default_node(manifest.name)}
              context={%{mode: :public}}
            />
          </div>
        </div>
        <div class="card-body p-4 gap-1">
          <div class="flex items-start justify-between gap-2">
            <span class="font-semibold text-sm group-hover:text-primary transition-colors">
              {manifest.label}
            </span>
            <span class="badge badge-ghost badge-xs shrink-0">{manifest.group}</span>
          </div>
          <p class="text-xs text-base-content/40">
            {length(manifest.variants)} {pluralize("variant", length(manifest.variants))}<span :if={
              manifest.slots != []
            }>
                · {length(manifest.slots)} {pluralize("slot", length(manifest.slots))}
              </span><span :if={
              manifest.alpine != %{}
            }>
               · Alpine
            </span>
          </p>
        </div>
      </.link>
    </div>
    """
  end

  attr :manifest, :map, required: true
  attr :selected_variant, :string, required: true
  attr :preview_node, :map, required: true
  attr :preview_width, :string, required: true
  attr :show_node_json, :boolean, required: true

  defp component_detail(assigns) do
    ~H"""
    <div class="grid gap-6 lg:grid-cols-[1fr_300px]">
      <%!-- Left: preview + variant controls + node JSON --%>
      <div class="min-w-0 space-y-5">
        <%!-- Meta badges --%>
        <div class="flex flex-wrap items-center gap-2">
          <span class="badge badge-primary">{@manifest.group}</span>
          <span :for={slot <- @manifest.slots} class="badge badge-ghost badge-sm">
            Slot: {slot.label}
          </span>
          <span :if={@manifest.alpine != %{}} class="badge badge-accent badge-sm">
            Alpine.js
          </span>
          <span :if={@manifest.accepted_children != []} class="badge badge-info badge-sm">
            Accepts children
          </span>
        </div>

        <%!-- Variant tabs --%>
        <div role="tablist" class="tabs tabs-box">
          <button
            :for={v <- @manifest.variants}
            role="tab"
            phx-click="select_variant"
            phx-value-variant={v.id}
            class={["tab", @selected_variant == v.id && "tab-active"]}
            title={v.description}
          >
            {v.label}
          </button>
        </div>

        <%!-- Responsive preview controls --%>
        <div class="flex items-center gap-3">
          <span class="shrink-0 text-xs text-base-content/50">Preview:</span>
          <div class="join">
            <button
              :for={
                {label, width, icon} <- [
                  {"Desktop", "full", "hero-computer-desktop"},
                  {"Tablet", "md", "hero-device-tablet"},
                  {"Mobile", "sm", "hero-device-phone-mobile"}
                ]
              }
              phx-click="set_preview_width"
              phx-value-width={width}
              class={[
                "btn btn-xs join-item gap-1",
                if(@preview_width == width,
                  do: "btn-primary",
                  else: "btn-ghost border border-base-300"
                )
              ]}
            >
              <.icon name={icon} class="size-3" />
              {label}
            </button>
          </div>
        </div>

        <%!-- Live preview --%>
        <div class="rounded-box border border-base-300 bg-base-200 p-4 overflow-x-auto">
          <div class={[
            "bg-base-100 rounded-box p-6 mx-auto transition-all duration-300",
            preview_width_class(@preview_width)
          ]}>
            <Renderer.node node={@preview_node} context={%{mode: :public}} />
          </div>
        </div>

        <%!-- Content tree node JSON --%>
        <div class="rounded-box border border-base-300 overflow-hidden">
          <button
            phx-click="toggle_node_json"
            class="flex w-full items-center justify-between p-3 text-sm font-medium hover:bg-base-200 transition-colors"
          >
            <div class="flex items-center gap-2">
              <.icon name="hero-code-bracket" class="size-4 text-base-content/50" /> Content tree node
            </div>
            <.icon
              name={if @show_node_json, do: "hero-chevron-up", else: "hero-chevron-down"}
              class="size-4 text-base-content/40"
            />
          </button>
          <div :if={@show_node_json} class="border-t border-base-300 p-4">
            <pre class="max-h-72 overflow-auto font-mono text-xs leading-relaxed text-base-content/70 whitespace-pre-wrap"><%= Jason.encode!(@preview_node, pretty: true) %></pre>
          </div>
        </div>
      </div>

      <%!-- Right: inspector panel --%>
      <div>
        <div class="rounded-box border border-base-300 bg-base-100 p-4 lg:sticky lg:top-4">
          <form phx-change="update_props" phx-submit="update_props">
            <Inspector.fields
              manifest={@manifest}
              node={@preview_node}
              variant_id={@selected_variant}
              id_prefix="ui-lib-inspector"
              form_name="node"
            />
          </form>
        </div>
      </div>
    </div>
    """
  end

  # ── Private helpers ───────────────────────────────────────────────────────────

  defp filtered_manifests(manifests, search, group) do
    manifests
    |> filter_by_group(group)
    |> filter_by_search(search)
  end

  defp filter_by_group(manifests, @all_group), do: manifests
  defp filter_by_group(manifests, group), do: Enum.filter(manifests, &(&1.group == group))

  defp filter_by_search(manifests, ""), do: manifests

  defp filter_by_search(manifests, q) do
    q = String.downcase(q)

    Enum.filter(manifests, fn m ->
      String.contains?(String.downcase(m.name), q) or
        String.contains?(String.downcase(m.label), q) or
        String.contains?(String.downcase(m.group), q)
    end)
  end

  defp count_in_group(manifests, @all_group), do: length(manifests)
  defp count_in_group(manifests, group), do: Enum.count(manifests, &(&1.group == group))

  defp apply_prop_changes(preview_node, params) do
    node_params = Map.get(params, "node", %{})
    prop_params = Map.get(node_params, "props", %{})
    class_params = Map.get(node_params, "classes", %{})

    new_props =
      Enum.reduce(prop_params, preview_node["props"], fn {key, val}, acc ->
        Map.put(acc, key, coerce_prop(val, Map.get(acc, key)))
      end)

    new_classes = Map.merge(preview_node["classes"], class_params)

    preview_node
    |> Map.put("props", new_props)
    |> Map.put("classes", new_classes)
  end

  defp coerce_prop("true", _), do: true
  defp coerce_prop("false", _), do: false

  defp coerce_prop(val, current) when is_integer(current) do
    case Integer.parse(to_string(val)) do
      {int, _} -> int
      :error -> current
    end
  end

  defp coerce_prop(val, _), do: val

  defp preview_width_class("sm"), do: "max-w-[375px]"
  defp preview_width_class("md"), do: "max-w-[768px]"
  defp preview_width_class(_), do: "w-full"

  defp pluralize(word, 1), do: word
  defp pluralize(word, _), do: word <> "s"
end
