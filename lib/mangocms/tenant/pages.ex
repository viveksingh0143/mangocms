defmodule MangoCMS.Tenant.Pages do
  @moduledoc "Tenant-local pages and reusable sections."

  import Ecto.Query

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.Accounts.User
  alias MangoCMS.Tenant.Collections
  alias MangoCMS.Tenant.Collections.CollectionItem

  alias MangoCMS.Tenant.Pages.{
    Page,
    PageVersion,
    Section,
    SectionVersion
  }

  alias MangoCMS.Tenant.RepoManager, as: TenantRepoManager

  @spec list_pages(Tenant.t()) :: [Page.t()]
  def list_pages(%Tenant{} = tenant) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      Page
      |> order_by([page], desc: page.inserted_at)
      |> repo.all()
    end)
  end

  @spec get_page!(Tenant.t(), String.t()) :: Page.t()
  def get_page!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get!(Page, id)
    end)
  end

  @spec get_page_with_sections!(Tenant.t(), String.t()) :: Page.t()
  def get_page_with_sections!(%Tenant{} = tenant, id) do
    get_page!(tenant, id)
  end

  @spec get_page_by_slug(Tenant.t(), String.t()) :: Page.t() | nil
  def get_page_by_slug(%Tenant{} = tenant, slug) when is_binary(slug) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get_by(Page, slug: slug)
    end)
  end

  @spec get_published_page_by_slug(Tenant.t(), String.t()) :: Page.t() | nil
  def get_published_page_by_slug(%Tenant{} = tenant, slug) when is_binary(slug) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      Page
      |> where([page], page.slug == ^slug and page.status == "published")
      |> repo.one()
    end)
  end

  @doc """
  Resolves linked section nodes and collection loops for public page rendering.

  Pages store embedded section references in their `content_tree`. Linked
  references are resolved from the section's published snapshot, while detached
  or local section nodes are rendered from their embedded children.
  """
  @spec resolve_page_content_tree(Tenant.t(), Page.t(), keyword()) :: list()
  def resolve_page_content_tree(%Tenant{} = tenant, %Page{} = page, opts \\ []) do
    resolve_tree(tenant, page.content_tree || [], %{}, opts)
  end

  @spec create_page(Tenant.t(), map()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def create_page(%Tenant{} = tenant, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %Page{}
      |> Page.changeset(attrs)
      |> repo.insert()
    end)
  end

  @spec update_page(Tenant.t(), Page.t(), map()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def update_page(%Tenant{} = tenant, %Page{} = page, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      page
      |> Page.changeset(attrs)
      |> repo.update()
    end)
  end

  @spec delete_page(Tenant.t(), Page.t()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def delete_page(%Tenant{} = tenant, %Page{} = page) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.delete(page)
    end)
  end

  @spec change_page(Page.t(), map()) :: Ecto.Changeset.t()
  def change_page(%Page{} = page, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

  @spec save_page_with_lock(Tenant.t(), Page.t(), map(), integer(), User.t() | nil) ::
          {:ok, Page.t()} | {:error, :stale} | {:error, Ecto.Changeset.t()}
  def save_page_with_lock(%Tenant{} = tenant, %Page{} = page, attrs, socket_version, user \\ nil)
      when is_integer(socket_version) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        current_page = repo.get!(Page, page.id)

        if current_page.content_tree_version != socket_version do
          repo.rollback(:stale)
        end

        {:ok, _version} =
          create_page_version_in_repo(repo, current_page, "auto", nil, user, %{
            change_summary: "Saved page builder changes"
          })

        current_page
        |> Page.tree_changeset(attrs)
        |> repo.update()
        |> case do
          {:ok, updated_page} -> updated_page
          {:error, changeset} -> repo.rollback(changeset)
        end
      end)
    end)
    |> case do
      {:ok, page} -> {:ok, page}
      {:error, :stale} -> {:error, :stale}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  @spec publish_page(Tenant.t(), Page.t(), User.t() | nil) ::
          {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def publish_page(%Tenant{} = tenant, %Page{} = page, user \\ nil) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        current_page = repo.get!(Page, page.id)

        if current_page.status != "published" do
          {:ok, _version} =
            create_page_version_in_repo(repo, current_page, "publish_checkpoint", nil, user, %{
              change_summary: "Published page"
            })
        end

        current_page
        |> Page.tree_changeset(%{status: "published"})
        |> repo.update()
        |> case do
          {:ok, updated_page} -> updated_page
          {:error, changeset} -> repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec archive_page(Tenant.t(), Page.t()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def archive_page(%Tenant{} = tenant, %Page{} = page) do
    update_page(tenant, page, %{status: "archived"})
  end

  @spec create_page_version(
          Tenant.t(),
          Page.t(),
          String.t(),
          String.t() | nil,
          User.t() | nil,
          map()
        ) ::
          {:ok, PageVersion.t()} | {:error, Ecto.Changeset.t()}
  def create_page_version(
        %Tenant{} = tenant,
        %Page{} = page,
        snapshot_type,
        label \\ nil,
        user \\ nil,
        attrs \\ %{}
      ) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      create_page_version_in_repo(repo, page, snapshot_type, label, user, attrs)
    end)
  end

  @spec list_page_versions(Tenant.t(), Page.t() | String.t()) :: [PageVersion.t()]
  def list_page_versions(%Tenant{} = tenant, page) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      page = resolve_page!(repo, page)

      PageVersion
      |> where([version], version.page_id == ^page.id)
      |> order_by([version], desc: version.version_number)
      |> preload(:created_by)
      |> repo.all()
    end)
  end

  @spec get_page_version!(Tenant.t(), String.t()) :: PageVersion.t()
  def get_page_version!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      PageVersion
      |> preload(:created_by)
      |> repo.get!(id)
    end)
  end

  @spec restore_page_to_version(Tenant.t(), Page.t(), PageVersion.t(), User.t() | nil) ::
          {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def restore_page_to_version(
        %Tenant{} = tenant,
        %Page{} = page,
        %PageVersion{} = version,
        user \\ nil
      ) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        current_page = repo.get!(Page, page.id)

        {:ok, _version} =
          create_page_version_in_repo(repo, current_page, "auto", "Pre-restore snapshot", user, %{
            change_summary: "Saved before restoring version #{version.version_number}",
            restored_from: version.version_number
          })

        current_page
        |> Page.tree_changeset(%{
          content_tree: version.content_tree,
          seo: current_page.seo || %{},
          title: current_page.title,
          slug: current_page.slug,
          type: current_page.type,
          status: current_page.status
        })
        |> repo.update()
        |> case do
          {:ok, updated_page} -> updated_page
          {:error, changeset} -> repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec prune_auto_page_versions(Tenant.t(), Page.t() | String.t(), pos_integer()) ::
          non_neg_integer()
  def prune_auto_page_versions(%Tenant{} = tenant, page, keep_limit \\ 50) when keep_limit > 0 do
    TenantRepoManager.with_repo(tenant, fn repo ->
      page = resolve_page!(repo, page)

      keep_ids =
        PageVersion
        |> where([version], version.page_id == ^page.id and version.snapshot_type == "auto")
        |> order_by([version], desc: version.version_number)
        |> limit(^keep_limit)
        |> select([version], version.id)
        |> repo.all()

      {count, _} =
        PageVersion
        |> where([version], version.page_id == ^page.id and version.snapshot_type == "auto")
        |> where([version], version.id not in ^keep_ids)
        |> repo.delete_all()

      count
    end)
  end

  @spec list_sections(Tenant.t()) :: [Section.t()]
  def list_sections(%Tenant{} = tenant) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      Section
      |> order_by([section], asc: section.group_label, asc: section.name)
      |> repo.all()
    end)
  end

  @spec get_section!(Tenant.t(), String.t()) :: Section.t()
  def get_section!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo -> repo.get!(Section, id) end)
  end

  @spec create_section(Tenant.t(), map()) :: {:ok, Section.t()} | {:error, Ecto.Changeset.t()}
  def create_section(%Tenant{} = tenant, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %Section{}
      |> Section.changeset(attrs)
      |> repo.insert()
    end)
  end

  @spec update_section(Tenant.t(), Section.t(), map(), User.t() | nil) ::
          {:ok, Section.t()} | {:error, Ecto.Changeset.t()}
  def update_section(
        %Tenant{} = tenant,
        %Section{} = section,
        attrs,
        user \\ nil
      ) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        {:ok, _version} =
          create_section_version_in_repo(repo, section, "auto", nil, user, %{
            change_summary: "Saved section changes"
          })

        section
        |> Section.changeset(attrs)
        |> repo.update()
        |> case do
          {:ok, updated_section} -> updated_section
          {:error, changeset} -> repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @doc """
  Publishes a section snapshot used by linked page embeds.

  Draft edits remain in the regular section fields. Public pages render the
  published fields so changes only affect linked pages after this explicit call.
  """
  @spec publish_section(Tenant.t(), Section.t(), User.t() | nil) ::
          {:ok, Section.t()} | {:error, Ecto.Changeset.t()}
  def publish_section(%Tenant{} = tenant, %Section{} = section, user \\ nil) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        current_section = repo.get!(Section, section.id)

        {:ok, _version} =
          create_section_version_in_repo(
            repo,
            current_section,
            "publish_checkpoint",
            nil,
            user,
            %{
              change_summary: "Published section"
            }
          )

        attrs = %{
          status: "published",
          published_content_tree: current_section.content_tree || [],
          published_settings: current_section.settings || %{},
          published_source_config: current_section.source_config || %{},
          published_filters: current_section.filters || %{},
          published_loop_settings: current_section.loop_settings || %{},
          published_at: DateTime.utc_now(:second)
        }

        current_section
        |> Section.changeset(attrs)
        |> repo.update()
        |> case do
          {:ok, updated_section} -> updated_section
          {:error, changeset} -> repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec delete_section(Tenant.t(), Section.t()) ::
          {:ok, Section.t()} | {:error, Ecto.Changeset.t()}
  def delete_section(%Tenant{} = tenant, %Section{} = section) do
    TenantRepoManager.with_repo(tenant, fn repo -> repo.delete(section) end)
  end

  @spec change_section(Section.t(), map()) :: Ecto.Changeset.t()
  def change_section(%Section{} = section, attrs \\ %{}) do
    Section.changeset(section, attrs)
  end

  @spec update_section_settings(Tenant.t(), Section.t(), map()) ::
          {:ok, Section.t()} | {:error, Ecto.Changeset.t()}
  def update_section_settings(%Tenant{} = tenant, %Section{} = section, settings) do
    attrs = %{
      settings: Map.merge(section.settings || %{}, stringify_keys(settings))
    }

    update_section(tenant, section, attrs)
  end

  defp resolve_page!(_repo, %Page{id: id} = page) when is_binary(id), do: page

  defp resolve_page!(repo, id_or_slug) when is_binary(id_or_slug) do
    repo.get(Page, id_or_slug) || repo.get_by!(Page, slug: id_or_slug)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp resolve_tree(%Tenant{} = tenant, nodes, bindings, opts) when is_list(nodes) do
    Enum.flat_map(nodes, fn node ->
      resolve_node(tenant, node, bindings, opts)
    end)
  end

  defp resolve_tree(_tenant, _nodes, _bindings, _opts), do: []

  defp resolve_node(%Tenant{} = tenant, %{"name" => "section_ref"} = node, bindings, opts) do
    props = node_map(node, "props")

    if linked_section?(node) do
      case Map.get(props, "section_id") do
        section_id when is_binary(section_id) ->
          section = get_section!(tenant, section_id)
          resolve_section(tenant, section, section_overrides(node), bindings, opts)

        _missing_section ->
          []
      end
    else
      [resolve_embedded_node(tenant, node, bindings, opts)]
    end
  rescue
    Ecto.NoResultsError -> []
  end

  defp resolve_node(%Tenant{} = tenant, %{"name" => "loop"} = node, bindings, opts) do
    loop_items = Map.get(bindings, "collection_results", [])
    item_alias = node |> node_map("props") |> Map.get("as", "item")

    loop_items
    |> Enum.flat_map(fn item ->
      item_bindings =
        bindings
        |> Map.put("item", item)
        |> Map.put(item_alias, item)

      tenant
      |> resolve_tree(children(node), item_bindings, opts)
      |> suffix_tree_ids(item["id"])
    end)
  end

  defp resolve_node(%Tenant{} = tenant, node, bindings, opts) when is_map(node) do
    [resolve_embedded_node(tenant, node, bindings, opts)]
  end

  defp resolve_node(_tenant, _node, _bindings, _opts), do: []

  defp resolve_section(%Tenant{} = tenant, %Section{} = section, overrides, bindings, opts) do
    public? = Keyword.get(opts, :public?, true)
    snapshot = section_snapshot(section, public?)

    cond do
      public? and snapshot.status != "published" ->
        []

      true ->
        section_bindings =
          bindings
          |> Map.put("section", section_to_binding(section))
          |> Map.put("collection_results", collection_results(tenant, snapshot))

        resolve_tree(tenant, snapshot.content_tree, section_bindings, opts)
        |> apply_section_overrides(overrides)
    end
  end

  defp resolve_embedded_node(%Tenant{} = tenant, node, bindings, opts) do
    node
    |> interpolate_node(bindings)
    |> Map.put("children", resolve_tree(tenant, children(node), bindings, opts))
  end

  defp section_snapshot(%Section{} = section, public?) do
    if public? and section.status == "published" do
      %{
        status: section.status,
        content_tree: section.published_content_tree || [],
        settings: section.published_settings || %{},
        source_config: section.published_source_config || %{},
        filters: section.published_filters || %{},
        loop_settings: section.published_loop_settings || %{}
      }
    else
      %{
        status: section.status,
        content_tree: section.content_tree || [],
        settings: section.settings || %{},
        source_config: section.source_config || %{},
        filters: section.filters || %{},
        loop_settings: section.loop_settings || %{}
      }
    end
  end

  defp collection_results(%Tenant{} = tenant, snapshot) do
    source_config = snapshot.source_config || %{}
    loop_settings = snapshot.loop_settings || %{}
    collection = source_config["collection_id"] || source_config["collection_slug"]

    if collection_source?(source_config) and is_binary(collection) do
      filters = snapshot.filters["rules"] || source_config["filters"] || []
      sort = source_config["sort"]
      limit = integer_value(loop_settings["limit"], 10)

      tenant
      |> Collections.list_entries(collection, filters: filters, sort: sort, limit: limit)
      |> Enum.map(&entry_binding/1)
    else
      []
    end
  rescue
    Ecto.NoResultsError -> []
  end

  defp collection_source?(%{"kind" => kind}) when kind in ["collection", "catalog"], do: true

  defp collection_source?(%{"collection_id" => collection_id}) when is_binary(collection_id),
    do: true

  defp collection_source?(%{"collection_slug" => collection_slug})
       when is_binary(collection_slug), do: true

  defp collection_source?(_source_config), do: false

  defp entry_binding(%CollectionItem{} = entry) do
    payload = entry.payload || %{}

    %{
      "id" => entry.id,
      "title" => entry.title,
      "slug" => entry.slug,
      "status" => entry.status,
      "payload" => payload,
      "inserted_at" => datetime_to_string(entry.inserted_at),
      "updated_at" => datetime_to_string(entry.updated_at),
      "published_at" => datetime_to_string(entry.published_at)
    }
    |> Map.merge(payload)
  end

  defp section_to_binding(%Section{} = section) do
    %{
      "id" => section.id,
      "name" => section.name,
      "template_key" => section.template_key,
      "group_label" => section.group_label,
      "mode" => section.mode
    }
  end

  defp apply_section_overrides(tree, overrides) when overrides == %{}, do: tree
  defp apply_section_overrides(tree, _overrides), do: tree

  defp suffix_tree_ids(tree, suffix) when is_list(tree) and is_binary(suffix) do
    Enum.map(tree, &suffix_node_id(&1, suffix))
  end

  defp suffix_tree_ids(tree, _suffix), do: tree

  defp suffix_node_id(node, suffix) when is_map(node) do
    node
    |> Map.update("id", nil, fn
      id when is_binary(id) -> "#{id}-#{suffix}"
      id -> id
    end)
    |> Map.update("children", [], &suffix_tree_ids(&1, suffix))
  end

  defp suffix_node_id(node, _suffix), do: node

  defp section_overrides(node), do: node_map(node, "overrides")

  defp linked_section?(node) do
    props = node_map(node, "props")
    Map.get(node, "template_linked", Map.get(props, "template_linked", true)) != false
  end

  defp interpolate_node(node, bindings) do
    node
    |> Map.update("props", %{}, &interpolate_value(&1, bindings))
    |> Map.update("classes", %{}, &interpolate_value(&1, bindings))
  end

  defp interpolate_value(value, bindings) when is_binary(value) do
    Regex.replace(~r/\{\{\s*([^}]+?)\s*\}\}/, value, fn _match, path ->
      bindings
      |> get_binding_path(path)
      |> binding_to_string()
    end)
  end

  defp interpolate_value(value, bindings) when is_map(value) do
    Map.new(value, fn {key, child_value} -> {key, interpolate_value(child_value, bindings)} end)
  end

  defp interpolate_value(value, bindings) when is_list(value) do
    Enum.map(value, &interpolate_value(&1, bindings))
  end

  defp interpolate_value(value, _bindings), do: value

  defp get_binding_path(bindings, path) when is_binary(path) do
    path
    |> String.split(".", trim: true)
    |> Enum.reduce_while(bindings, fn key, acc ->
      case acc do
        map when is_map(map) ->
          {:cont, Map.get(map, key)}

        _other ->
          {:halt, nil}
      end
    end)
  rescue
    ArgumentError -> nil
  end

  defp binding_to_string(nil), do: ""
  defp binding_to_string(value) when is_binary(value), do: value
  defp binding_to_string(value) when is_integer(value), do: Integer.to_string(value)
  defp binding_to_string(value) when is_float(value), do: Float.to_string(value)
  defp binding_to_string(value) when is_boolean(value), do: to_string(value)
  defp binding_to_string(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp binding_to_string(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp binding_to_string(%Date{} = value), do: Date.to_iso8601(value)
  defp binding_to_string(value) when is_map(value), do: Map.get(value, "url", "")
  defp binding_to_string(_value), do: ""

  defp children(%{"children" => children}) when is_list(children), do: children
  defp children(_node), do: []

  defp node_map(node, key) when is_map(node) do
    case Map.get(node, key) do
      value when is_map(value) -> value
      _other -> %{}
    end
  end

  defp integer_value(value, _default) when is_integer(value) and value > 0, do: value

  defp integer_value(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _other -> default
    end
  end

  defp integer_value(_value, default), do: default

  defp datetime_to_string(nil), do: nil
  defp datetime_to_string(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp datetime_to_string(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)

  defp create_page_version_in_repo(repo, %Page{} = page, snapshot_type, label, user, attrs) do
    page_id = page.id

    next_version_number =
      PageVersion
      |> where([version], version.page_id == ^page_id)
      |> select([version], max(version.version_number))
      |> repo.one()
      |> Kernel.||(0)
      |> Kernel.+(1)

    attrs =
      attrs
      |> stringify_keys()
      |> Map.merge(%{
        "page_id" => page.id,
        "created_by_id" => user_id(user),
        "content_tree" => page.content_tree || [],
        "version_number" => next_version_number,
        "label" => label,
        "snapshot_type" => snapshot_type
      })

    %PageVersion{}
    |> PageVersion.changeset(attrs)
    |> repo.insert()
  end

  defp create_section_version_in_repo(
         repo,
         %Section{} = section,
         snapshot_type,
         label,
         user,
         attrs
       ) do
    section_id = section.id

    next_version_number =
      SectionVersion
      |> where([version], version.section_id == ^section_id)
      |> select([version], max(version.version_number))
      |> repo.one()
      |> Kernel.||(0)
      |> Kernel.+(1)

    attrs =
      attrs
      |> stringify_keys()
      |> Map.merge(%{
        "section_id" => section.id,
        "created_by_id" => user_id(user),
        "content_tree" => section.content_tree || [],
        "version_number" => next_version_number,
        "label" => label,
        "snapshot_type" => snapshot_type
      })

    %SectionVersion{}
    |> SectionVersion.changeset(attrs)
    |> repo.insert()
  end

  defp user_id(%User{id: id}) when is_binary(id), do: id
  defp user_id(_user), do: nil

  defp unwrap_transaction({:ok, value}), do: {:ok, value}
  defp unwrap_transaction({:error, {type, changeset}}), do: {:error, {type, changeset}}
  defp unwrap_transaction({:error, changeset}), do: {:error, changeset}
end
