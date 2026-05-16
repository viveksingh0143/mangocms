defmodule MangoCMS.ContentTree do
  @moduledoc """
  Pure functional AST manipulations for page-builder content trees.

  This module intentionally has no Phoenix, LiveView, or Ecto dependencies. It
  operates only on JSON-compatible maps and lists so every mutation can be
  tested in isolation before the editor or persistence layers call it.
  """

  @children_key "children"
  @classes_key "classes"
  @id_key "id"
  @path_key "path"
  @props_key "props"
  @root_path "root"

  @type block_node :: map()
  @type tree :: [block_node()]
  @type position :: :before | :after | :into
  @type tree_diff :: %{added: [String.t()], removed: [String.t()], changed: [String.t()]}

  # ---------------------------------------------------------------------------
  # Public traversal API
  # ---------------------------------------------------------------------------

  @doc """
  Finds a node anywhere in the tree by its string id.

  Returns `nil` when the id cannot be found.
  """
  @spec find_node(tree(), String.t()) :: block_node() | nil
  def find_node(tree, id) when is_list(tree) and is_binary(id) do
    Enum.find_value(tree, fn node ->
      if node_id(node) == id do
        node
      else
        find_node(node_children(node), id)
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Public mutation API
  # ---------------------------------------------------------------------------

  @doc """
  Normalizes all materialized paths in a tree.

  This is useful after constructing a new tree from palette presets, seeds, or
  imported JSON.
  """
  @spec normalize_paths(tree()) :: tree()
  def normalize_paths(tree) when is_list(tree), do: recompute_paths(tree)

  @doc """
  Inserts `node` relative to `target_id`.

  `target_id` may be `"root"` for top-level inserts. The same positions as
  `move_node/4` are supported.
  """
  @spec insert_node(tree(), String.t(), block_node(), position()) :: tree()
  def insert_node(tree, "root", node, position)
      when is_list(tree) and is_map(node) and position in [:before, :after, :into] do
    case position do
      :before -> recompute_paths([node | tree])
      :after -> recompute_paths(tree ++ [node])
      :into -> recompute_paths(tree ++ [node])
    end
  end

  def insert_node(tree, target_id, node, position)
      when is_list(tree) and is_binary(target_id) and is_map(node) and
             position in [:before, :after, :into] do
    {updated_tree, inserted?} = insert_node_in(tree, target_id, node, position)

    if inserted? do
      recompute_paths(updated_tree)
    else
      tree
    end
  end

  @doc """
  Merges `props` into the target node's existing `props` map.

  Missing nodes leave the tree unchanged apart from path normalization.
  """
  @spec update_node_props(tree(), String.t(), map()) :: tree()
  def update_node_props(tree, id, props) when is_list(tree) and is_binary(id) and is_map(props) do
    tree
    |> update_node(id, fn node ->
      Map.put(node, @props_key, Map.merge(node_map(node, @props_key), props))
    end)
    |> recompute_paths()
  end

  @doc """
  Merges `classes` into the target node's existing categorized class map.

  The builder stores Tailwind/daisyUI classes under categories such as
  `"display"`, `"padding"`, `"margin"`, `"daisy_ui"`, and `"custom"`.
  """
  @spec update_node_classes(tree(), String.t(), map()) :: tree()
  def update_node_classes(tree, id, classes)
      when is_list(tree) and is_binary(id) and is_map(classes) do
    tree
    |> update_node(id, fn node ->
      Map.put(node, @classes_key, Map.merge(node_map(node, @classes_key), classes))
    end)
    |> recompute_paths()
  end

  @doc """
  Moves `node_id` relative to `target_id`.

  Supported positions are:

  * `:before` - insert as a sibling immediately before the target
  * `:after` - insert as a sibling immediately after the target
  * `:into` - append as the last child of the target

  Invalid moves, missing ids, and attempts to move a node into its own
  descendant return the original tree unchanged.
  """
  @spec move_node(tree(), String.t(), String.t(), position()) :: tree()
  def move_node(tree, node_id, target_id, position)
      when is_list(tree) and is_binary(node_id) and is_binary(target_id) and
             position in [:before, :after, :into] do
    moving_node = find_node(tree, node_id)
    target_node = find_node(tree, target_id)

    cond do
      is_nil(moving_node) ->
        tree

      target_id == @root_path ->
        {tree_without_node, popped_node} = pop_node(tree, node_id)

        case popped_node do
          nil -> tree
          node -> insert_node(tree_without_node, @root_path, node, position)
        end

      is_nil(target_node) ->
        tree

      node_id == target_id ->
        tree

      descendant_id?(moving_node, target_id) ->
        tree

      true ->
        do_move_node(tree, node_id, target_id, position)
    end
  end

  @doc """
  Deletes a node and its descendants from the tree.

  Paths are normalized after deletion.
  """
  @spec delete_node(tree(), String.t()) :: tree()
  def delete_node(tree, id) when is_list(tree) and is_binary(id) do
    {updated_tree, _deleted?} = delete_node_in(tree, id)
    recompute_paths(updated_tree)
  end

  @doc """
  Compares two trees by node id.

  The returned ids mean:

  * `:added` - ids present in `tree_b` but not `tree_a`
  * `:removed` - ids present in `tree_a` but not `tree_b`
  * `:changed` - ids present in both trees whose own fields changed

  Child lists are excluded from per-node comparison so adding a child does not
  mark every ancestor as changed. Structural moves are still reported because
  the node's materialized `path` changes.
  """
  @spec diff_trees(tree(), tree()) :: tree_diff()
  def diff_trees(tree_a, tree_b) when is_list(tree_a) and is_list(tree_b) do
    flat_a = flatten_nodes(tree_a)
    flat_b = flatten_nodes(tree_b)

    ids_a = Map.keys(flat_a)
    ids_b = Map.keys(flat_b)

    added = Enum.reject(ids_b, &Map.has_key?(flat_a, &1))
    removed = Enum.reject(ids_a, &Map.has_key?(flat_b, &1))

    changed =
      ids_b
      |> Enum.filter(&Map.has_key?(flat_a, &1))
      |> Enum.filter(fn id -> comparable_node(flat_a[id]) != comparable_node(flat_b[id]) end)

    %{added: added, removed: removed, changed: changed}
  end

  # ---------------------------------------------------------------------------
  # Mutation internals
  # ---------------------------------------------------------------------------

  defp do_move_node(tree, node_id, target_id, position) do
    {tree_without_node, popped_node} = pop_node(tree, node_id)

    case popped_node do
      nil ->
        tree

      node ->
        {updated_tree, inserted?} = insert_node_in(tree_without_node, target_id, node, position)

        if inserted? do
          recompute_paths(updated_tree)
        else
          tree
        end
    end
  end

  defp update_node(nodes, id, updater) do
    Enum.map(nodes, fn node ->
      if node_id(node) == id do
        updater.(node)
      else
        updated_children = update_node(node_children(node), id, updater)
        maybe_put_children(node, updated_children)
      end
    end)
  end

  defp delete_node_in(nodes, id) do
    Enum.reduce(nodes, {[], false}, fn node, {acc, deleted?} ->
      if node_id(node) == id do
        {acc, true}
      else
        {updated_children, child_deleted?} = delete_node_in(node_children(node), id)
        {[maybe_put_children(node, updated_children) | acc], deleted? or child_deleted?}
      end
    end)
    |> then(fn {nodes, deleted?} -> {Enum.reverse(nodes), deleted?} end)
  end

  defp pop_node(nodes, id) do
    Enum.reduce(nodes, {[], nil}, fn node, {acc, popped_node} ->
      cond do
        popped_node ->
          {[node | acc], popped_node}

        node_id(node) == id ->
          {acc, node}

        true ->
          {updated_children, child_popped_node} = pop_node(node_children(node), id)
          updated_node = maybe_put_children(node, updated_children)
          {[updated_node | acc], child_popped_node}
      end
    end)
    |> then(fn {nodes, popped_node} -> {Enum.reverse(nodes), popped_node} end)
  end

  defp insert_node_in(nodes, target_id, node, position) when position in [:before, :after] do
    Enum.reduce(nodes, {[], false}, fn current_node, {acc, inserted?} ->
      cond do
        inserted? ->
          {[current_node | acc], true}

        node_id(current_node) == target_id and position == :before ->
          {[current_node, node | acc], true}

        node_id(current_node) == target_id and position == :after ->
          {[node, current_node | acc], true}

        true ->
          {updated_children, child_inserted?} =
            insert_node_in(node_children(current_node), target_id, node, position)

          updated_node = maybe_put_children(current_node, updated_children)
          {[updated_node | acc], child_inserted?}
      end
    end)
    |> then(fn {nodes, inserted?} -> {Enum.reverse(nodes), inserted?} end)
  end

  defp insert_node_in(nodes, target_id, node, :into) do
    Enum.reduce(nodes, {[], false}, fn current_node, {acc, inserted?} ->
      cond do
        inserted? ->
          {[current_node | acc], true}

        node_id(current_node) == target_id ->
          updated_children = node_children(current_node) ++ [node]
          {[Map.put(current_node, @children_key, updated_children) | acc], true}

        true ->
          {updated_children, child_inserted?} =
            insert_node_in(node_children(current_node), target_id, node, :into)

          updated_node = maybe_put_children(current_node, updated_children)
          {[updated_node | acc], child_inserted?}
      end
    end)
    |> then(fn {nodes, inserted?} -> {Enum.reverse(nodes), inserted?} end)
  end

  # ---------------------------------------------------------------------------
  # Path and diff internals
  # ---------------------------------------------------------------------------

  defp recompute_paths(tree) do
    assign_paths(tree, @root_path)
  end

  defp assign_paths(nodes, parent_path) do
    Enum.map(nodes, fn node ->
      node_path = parent_path
      child_parent_path = join_path(parent_path, node_id(node))

      node
      |> Map.put(@path_key, node_path)
      |> maybe_put_children(assign_paths(node_children(node), child_parent_path))
    end)
  end

  defp join_path(parent_path, nil), do: parent_path
  defp join_path(parent_path, ""), do: parent_path
  defp join_path(parent_path, id), do: parent_path <> "." <> id

  defp flatten_nodes(tree) do
    tree
    |> flatten_nodes([])
    |> Enum.reverse()
    |> Map.new()
  end

  defp flatten_nodes(nodes, acc) do
    Enum.reduce(nodes, acc, fn node, acc ->
      id = node_id(node)
      acc = if is_binary(id), do: [{id, node} | acc], else: acc
      flatten_nodes(node_children(node), acc)
    end)
  end

  defp comparable_node(node) do
    Map.delete(node, @children_key)
  end

  # ---------------------------------------------------------------------------
  # Node shape helpers
  # ---------------------------------------------------------------------------

  defp descendant_id?(node, target_id) do
    node
    |> node_children()
    |> Enum.any?(fn child -> node_id(child) == target_id or descendant_id?(child, target_id) end)
  end

  defp node_id(%{} = node), do: Map.get(node, @id_key)
  defp node_id(_node), do: nil

  defp node_children(%{} = node) do
    case Map.get(node, @children_key) do
      children when is_list(children) -> children
      _other -> []
    end
  end

  defp node_children(_node), do: []

  defp node_map(%{} = node, key) do
    case Map.get(node, key) do
      value when is_map(value) -> value
      _other -> %{}
    end
  end

  defp maybe_put_children(%{} = node, children) when is_list(children) do
    if Map.has_key?(node, @children_key) or children != [] do
      Map.put(node, @children_key, children)
    else
      Map.delete(node, @children_key)
    end
  end
end
