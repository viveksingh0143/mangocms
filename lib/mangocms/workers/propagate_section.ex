defmodule MangoCMS.Workers.PropagateSection do
  @moduledoc """
  Re-embeds an updated reusable section into pages that still reference it.

  Page instances marked with `props["unlinked"] == true` are skipped so page
  builders can intentionally customize a section instance locally.
  """

  use Oban.Worker, queue: :default

  alias MangoCMS.Platform
  alias MangoCMS.Tenant.Pages
  alias MangoCMS.Tenant.Pages.Page

  @impl true
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id, "section_id" => section_id}}) do
    tenant = Platform.get_tenant!(tenant_id)
    section = Pages.get_section!(tenant, section_id)

    tenant
    |> Pages.list_pages()
    |> Enum.each(fn page ->
      maybe_update_page(tenant, page, section_id, section.content_tree || [])
    end)

    :ok
  end

  defp maybe_update_page(tenant, %Page{} = page, section_id, content_tree) do
    {tree, changed?} = replace_section_nodes(page.content_tree || [], section_id, content_tree)

    if changed? do
      Pages.update_page(tenant, page, %{content_tree: tree})
    end
  end

  defp replace_section_nodes(nodes, section_id, content_tree) do
    Enum.map_reduce(nodes, false, fn node, changed? ->
      cond do
        section_node?(node, section_id) and not unlinked?(node) ->
          updated_node = Map.put(node, "children", content_tree)
          {updated_node, true}

        is_list(node["children"]) ->
          {children, child_changed?} =
            replace_section_nodes(node["children"], section_id, content_tree)

          {Map.put(node, "children", children), changed? or child_changed?}

        true ->
          {node, changed?}
      end
    end)
  end

  defp section_node?(%{"name" => "section_ref", "props" => %{"section_id" => id}}, section_id),
    do: id == section_id

  defp section_node?(_node, _section_id), do: false

  defp unlinked?(%{"props" => %{"unlinked" => true}}), do: true
  defp unlinked?(_node), do: false
end
