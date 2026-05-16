defmodule MangoCMS.Workers.PropagateGlobalSection do
  @moduledoc """
  Propagates a tenant global section tree into pages that reference it.

  Nodes with `props["unlinked"] == true` are treated as local copies and are
  intentionally skipped.
  """

  use Oban.Worker, queue: :default

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.Pages
  alias MangoCMS.Tenant.Pages.Page

  @impl true
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{
        args: %{"tenant_id" => tenant_id, "global_section_id" => global_section_id}
      }) do
    tenant = Platform.get_tenant_with_plan!(tenant_id)
    global_section = Pages.get_global_section!(tenant, global_section_id)

    tenant
    |> Pages.list_pages()
    |> Enum.each(fn page ->
      maybe_update_page(tenant, page, global_section_id, global_section.content_tree || [])
    end)

    :ok
  end

  defp maybe_update_page(tenant, %Page{} = page, global_section_id, content_tree) do
    {tree, changed?} =
      replace_global_section_nodes(page.content_tree || [], global_section_id, content_tree)

    if changed? do
      Pages.save_page_with_lock(
        tenant,
        page,
        %{
          title: page.title,
          slug: page.slug,
          type: page.type,
          status: page.status,
          seo: page.seo || %{},
          content_tree: tree
        },
        page.content_tree_version || 1
      )
    end

    :ok
  end

  defp replace_global_section_nodes(nodes, global_section_id, content_tree) do
    Enum.map_reduce(nodes, false, fn node, changed? ->
      cond do
        global_section_node?(node, global_section_id) and not unlinked?(node) ->
          {Map.put(node, "children", content_tree), true}

        is_list(Map.get(node, "children")) ->
          {children, child_changed?} =
            replace_global_section_nodes(node["children"], global_section_id, content_tree)

          {Map.put(node, "children", children), changed? or child_changed?}

        true ->
          {node, changed?}
      end
    end)
  end

  defp global_section_node?(
         %{"name" => "global_section", "props" => %{"global_section_id" => id}},
         id
       ),
       do: true

  defp global_section_node?(_node, _id), do: false

  defp unlinked?(%{"props" => %{"unlinked" => true}}), do: true
  defp unlinked?(%{"props" => %{"unlinked" => "true"}}), do: true
  defp unlinked?(_node), do: false
end
