defmodule MangoCMS.Tenant.Pages do
  @moduledoc "Tenant-local pages and page sections."

  import Ecto.Query

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.Accounts.User

  alias MangoCMS.Tenant.Pages.{
    GlobalSection,
    GlobalSectionVersion,
    Page,
    PageSection,
    PageVersion,
    SectionMapping,
    SectionSource
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
    TenantRepoManager.with_repo(tenant, fn repo ->
      Page
      |> where([page], page.id == ^id)
      |> preload(sections: ^sections_query())
      |> repo.one!()
    end)
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
      |> preload(sections: ^sections_query())
      |> repo.one()
    end)
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

  @spec list_global_sections(Tenant.t()) :: [GlobalSection.t()]
  def list_global_sections(%Tenant{} = tenant) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      GlobalSection
      |> order_by([section], asc: section.name)
      |> repo.all()
    end)
  end

  @spec get_global_section!(Tenant.t(), String.t()) :: GlobalSection.t()
  def get_global_section!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo -> repo.get!(GlobalSection, id) end)
  end

  @spec create_global_section(Tenant.t(), map()) ::
          {:ok, GlobalSection.t()} | {:error, Ecto.Changeset.t()}
  def create_global_section(%Tenant{} = tenant, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %GlobalSection{}
      |> GlobalSection.changeset(attrs)
      |> repo.insert()
    end)
  end

  @spec update_global_section(Tenant.t(), GlobalSection.t(), map(), User.t() | nil) ::
          {:ok, GlobalSection.t()} | {:error, Ecto.Changeset.t()}
  def update_global_section(
        %Tenant{} = tenant,
        %GlobalSection{} = global_section,
        attrs,
        user \\ nil
      ) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        {:ok, _version} =
          create_global_section_version_in_repo(repo, global_section, "auto", nil, user, %{
            change_summary: "Saved global section changes"
          })

        global_section
        |> GlobalSection.changeset(attrs)
        |> repo.update()
        |> case do
          {:ok, updated_global_section} -> updated_global_section
          {:error, changeset} -> repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec delete_global_section(Tenant.t(), GlobalSection.t()) ::
          {:ok, GlobalSection.t()} | {:error, Ecto.Changeset.t()}
  def delete_global_section(%Tenant{} = tenant, %GlobalSection{} = global_section) do
    TenantRepoManager.with_repo(tenant, fn repo -> repo.delete(global_section) end)
  end

  @spec list_sections(Tenant.t(), Page.t() | String.t()) :: [PageSection.t()]
  def list_sections(%Tenant{} = tenant, page) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      page = resolve_page!(repo, page)

      PageSection
      |> where([section], section.page_id == ^page.id)
      |> order_by([section], asc: section.position, asc: section.inserted_at)
      |> preload([section], [:source, mappings: ^mappings_query()])
      |> repo.all()
    end)
  end

  @spec get_section!(Tenant.t(), String.t()) :: PageSection.t()
  def get_section!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      PageSection
      |> preload([section], [:source, mappings: ^mappings_query()])
      |> repo.get!(id)
    end)
  end

  @spec create_section(Tenant.t(), Page.t(), map()) ::
          {:ok, PageSection.t()} | {:error, Ecto.Changeset.t()}
  def create_section(%Tenant{} = tenant, %Page{} = page, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %PageSection{page_id: page.id}
      |> PageSection.changeset(attrs)
      |> repo.insert()
    end)
  end

  @spec update_section(Tenant.t(), PageSection.t(), map()) ::
          {:ok, PageSection.t()} | {:error, Ecto.Changeset.t()}
  def update_section(%Tenant{} = tenant, %PageSection{} = section, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      section
      |> PageSection.changeset(attrs)
      |> repo.update()
    end)
  end

  @spec delete_section(Tenant.t(), PageSection.t()) ::
          {:ok, PageSection.t()} | {:error, Ecto.Changeset.t()}
  def delete_section(%Tenant{} = tenant, %PageSection{} = section) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.delete(section)
    end)
  end

  @spec change_section(PageSection.t(), map()) :: Ecto.Changeset.t()
  def change_section(%PageSection{} = section, attrs \\ %{}) do
    PageSection.changeset(section, attrs)
  end

  @spec update_section_settings(Tenant.t(), PageSection.t(), map()) ::
          {:ok, PageSection.t()} | {:error, Ecto.Changeset.t()}
  def update_section_settings(%Tenant{} = tenant, %PageSection{} = section, settings) do
    attrs = %{
      settings: Map.merge(section.settings || %{}, stringify_keys(settings))
    }

    update_section(tenant, section, attrs)
  end

  @spec reorder_sections(Tenant.t(), Page.t() | String.t(), [String.t()]) :: :ok
  def reorder_sections(%Tenant{} = tenant, page, ordered_ids) when is_list(ordered_ids) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      page = resolve_page!(repo, page)

      sections =
        PageSection
        |> where([section], section.page_id == ^page.id)
        |> order_by([section], asc: section.position, asc: section.inserted_at)
        |> repo.all()

      sections_by_id = Map.new(sections, &{&1.id, &1})

      ordered_ids =
        ordered_ids
        |> Enum.filter(&Map.has_key?(sections_by_id, &1))
        |> Enum.uniq()

      missing_ids =
        sections
        |> Enum.map(& &1.id)
        |> Enum.reject(&(&1 in ordered_ids))

      repo.transaction(fn ->
        (ordered_ids ++ missing_ids)
        |> Enum.with_index(1)
        |> Enum.each(fn {id, index} ->
          PageSection
          |> where([section], section.id == ^id and section.page_id == ^page.id)
          |> repo.update_all(set: [position: index * 10])
        end)
      end)

      :ok
    end)
  end

  @spec create_section_configuration(Tenant.t(), Page.t(), map(), map(), list(map())) ::
          {:ok, PageSection.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, {:source | :mapping, Ecto.Changeset.t()}}
  def create_section_configuration(
        %Tenant{} = tenant,
        %Page{} = page,
        attrs,
        source_attrs,
        mappings
      ) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        with {:ok, section} <-
               %PageSection{page_id: page.id}
               |> PageSection.changeset(attrs)
               |> repo.insert(),
             :ok <- sync_section_source_and_mappings(repo, section, source_attrs, mappings) do
          repo.preload(section, [:source, mappings: mappings_query()])
        else
          {:error, %Ecto.Changeset{} = changeset} -> repo.rollback(changeset)
          {:error, type, %Ecto.Changeset{} = changeset} -> repo.rollback({type, changeset})
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec update_section_configuration(Tenant.t(), PageSection.t(), map(), map(), list(map())) ::
          {:ok, PageSection.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, {:source | :mapping, Ecto.Changeset.t()}}
  def update_section_configuration(
        %Tenant{} = tenant,
        %PageSection{} = section,
        attrs,
        source_attrs,
        mappings
      ) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        with {:ok, section} <- section |> PageSection.changeset(attrs) |> repo.update(),
             :ok <- sync_section_source_and_mappings(repo, section, source_attrs, mappings) do
          repo.preload(section, [:source, mappings: mappings_query()])
        else
          {:error, %Ecto.Changeset{} = changeset} -> repo.rollback(changeset)
          {:error, type, %Ecto.Changeset{} = changeset} -> repo.rollback({type, changeset})
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec get_section_source(Tenant.t(), PageSection.t() | String.t()) :: SectionSource.t() | nil
  def get_section_source(%Tenant{} = tenant, section) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      section = resolve_section!(repo, section)
      repo.get_by(SectionSource, page_section_id: section.id)
    end)
  end

  @spec list_section_mappings(Tenant.t(), PageSection.t() | String.t()) :: [SectionMapping.t()]
  def list_section_mappings(%Tenant{} = tenant, section) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      section = resolve_section!(repo, section)

      SectionMapping
      |> where([mapping], mapping.page_section_id == ^section.id)
      |> order_by([mapping], asc: mapping.position, asc: mapping.inserted_at)
      |> repo.all()
    end)
  end

  @spec change_section_source(SectionSource.t(), map()) :: Ecto.Changeset.t()
  def change_section_source(%SectionSource{} = source, attrs \\ %{}) do
    SectionSource.changeset(source, attrs)
  end

  @spec change_section_mapping(SectionMapping.t(), map()) :: Ecto.Changeset.t()
  def change_section_mapping(%SectionMapping{} = mapping, attrs \\ %{}) do
    SectionMapping.changeset(mapping, attrs)
  end

  @spec default_section_mappings() :: [map()]
  def default_section_mappings do
    [
      %{"slot" => "eyebrow", "source_path" => "", "formatter" => "badge", "position" => 10},
      %{"slot" => "title", "source_path" => "title", "formatter" => "text", "position" => 20},
      %{
        "slot" => "subtitle",
        "source_path" => "payload.description",
        "formatter" => "excerpt",
        "position" => 30
      },
      %{"slot" => "body", "source_path" => "", "formatter" => "excerpt", "position" => 40},
      %{
        "slot" => "image",
        "source_path" => "payload.image_url",
        "formatter" => "image",
        "position" => 50
      },
      %{
        "slot" => "price",
        "source_path" => "payload.price",
        "formatter" => "currency",
        "position" => 60
      },
      %{"slot" => "cta_href", "source_path" => "slug", "formatter" => "url", "position" => 70}
    ]
  end

  @spec section_render_items(Tenant.t(), [PageSection.t()]) :: %{optional(String.t()) => [map()]}
  def section_render_items(%Tenant{} = tenant, sections) when is_list(sections) do
    sections
    |> Enum.filter(&dynamic_section?/1)
    |> Map.new(fn section ->
      {section.id, list_section_entries(tenant, section)}
    end)
  end

  @spec list_section_entries(Tenant.t(), PageSection.t()) :: [map()]
  def list_section_entries(%Tenant{} = tenant, %PageSection{} = section) do
    with true <- dynamic_section?(section),
         %SectionSource{} = source <-
           loaded_source(section) || get_section_source(tenant, section) do
      ContentEngine.list_entries(tenant, source.content_type_id,
        status: source.status,
        filters: source_filters(source),
        sort: source_sort(source),
        limit: source.limit,
        offset: source.offset
      )
    else
      _other -> []
    end
  end

  defp resolve_page!(_repo, %Page{id: id} = page) when is_binary(id), do: page

  defp resolve_page!(repo, id_or_slug) when is_binary(id_or_slug) do
    repo.get(Page, id_or_slug) || repo.get_by!(Page, slug: id_or_slug)
  end

  defp resolve_section!(_repo, %PageSection{id: id} = section) when is_binary(id), do: section

  defp resolve_section!(repo, id) when is_binary(id), do: repo.get!(PageSection, id)

  defp sections_query do
    from section in PageSection,
      order_by: [asc: section.position, asc: section.inserted_at],
      preload: [:source, mappings: ^mappings_query()]
  end

  defp mappings_query do
    from mapping in SectionMapping,
      order_by: [asc: mapping.position, asc: mapping.inserted_at]
  end

  defp sync_section_source_and_mappings(
         repo,
         %PageSection{mode: "fixed"} = section,
         _source,
         _mappings
       ) do
    clear_section_source_and_mappings(repo, section)
    :ok
  end

  defp sync_section_source_and_mappings(repo, %PageSection{} = section, source_attrs, mappings) do
    with :ok <- upsert_section_source(repo, section, source_attrs),
         :ok <- replace_section_mappings(repo, section, mappings) do
      :ok
    end
  end

  defp clear_section_source_and_mappings(repo, %PageSection{} = section) do
    SectionSource
    |> where([source], source.page_section_id == ^section.id)
    |> repo.delete_all()

    SectionMapping
    |> where([mapping], mapping.page_section_id == ^section.id)
    |> repo.delete_all()
  end

  defp upsert_section_source(repo, %PageSection{} = section, attrs) do
    source =
      repo.get_by(SectionSource, page_section_id: section.id) ||
        %SectionSource{page_section_id: section.id}

    case source |> SectionSource.changeset(attrs || %{}) |> repo.insert_or_update() do
      {:ok, _source} -> :ok
      {:error, changeset} -> {:error, :source, changeset}
    end
  end

  defp replace_section_mappings(repo, %PageSection{} = section, mappings) do
    existing =
      SectionMapping
      |> where([mapping], mapping.page_section_id == ^section.id)
      |> repo.all()
      |> Map.new(&{&1.slot, &1})

    mappings
    |> normalize_mapping_attrs()
    |> Enum.reduce_while(:ok, fn attrs, :ok ->
      slot = Map.get(attrs, "slot")
      source_path = Map.get(attrs, "source_path")

      cond do
        blank?(slot) ->
          {:cont, :ok}

        blank?(source_path) ->
          existing
          |> Map.get(slot)
          |> maybe_delete_mapping(repo)

          {:cont, :ok}

        true ->
          mapping = Map.get(existing, slot) || %SectionMapping{page_section_id: section.id}

          case mapping |> SectionMapping.changeset(attrs) |> repo.insert_or_update() do
            {:ok, _mapping} -> {:cont, :ok}
            {:error, changeset} -> {:halt, {:error, :mapping, changeset}}
          end
      end
    end)
  end

  defp normalize_mapping_attrs(nil), do: []

  defp normalize_mapping_attrs(mappings) when is_map(mappings) do
    mappings
    |> Map.values()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&string_key_map/1)
  end

  defp normalize_mapping_attrs(mappings) when is_list(mappings),
    do: mappings |> Enum.filter(&is_map/1) |> Enum.map(&string_key_map/1)

  defp normalize_mapping_attrs(_mappings), do: []

  defp maybe_delete_mapping(nil, _repo), do: :ok

  defp maybe_delete_mapping(%SectionMapping{} = mapping, repo) do
    repo.delete(mapping)
    :ok
  end

  defp dynamic_section?(%PageSection{mode: mode}), do: mode in ["dynamic", "reference"]
  defp dynamic_section?(_section), do: false

  defp loaded_source(%PageSection{source: %SectionSource{} = source}), do: source
  defp loaded_source(_section), do: nil

  defp source_filters(%SectionSource{filters: filters}) when map_size(filters) == 0, do: []

  defp source_filters(%SectionSource{filters: %{"items" => filters}}) when is_list(filters),
    do: filters

  defp source_filters(%SectionSource{filters: filters}) when is_map(filters), do: filters
  defp source_filters(_source), do: []

  defp source_sort(%SectionSource{sort: sort}) when map_size(sort) == 0, do: nil
  defp source_sort(%SectionSource{sort: sort}) when is_map(sort), do: sort
  defp source_sort(_source), do: nil

  defp blank?(value), do: value in [nil, ""]

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp string_key_map(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

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

  defp create_global_section_version_in_repo(
         repo,
         %GlobalSection{} = global_section,
         snapshot_type,
         label,
         user,
         attrs
       ) do
    global_section_id = global_section.id

    next_version_number =
      GlobalSectionVersion
      |> where([version], version.global_section_id == ^global_section_id)
      |> select([version], max(version.version_number))
      |> repo.one()
      |> Kernel.||(0)
      |> Kernel.+(1)

    attrs =
      attrs
      |> stringify_keys()
      |> Map.merge(%{
        "global_section_id" => global_section.id,
        "created_by_id" => user_id(user),
        "content_tree" => global_section.content_tree || [],
        "version_number" => next_version_number,
        "label" => label,
        "snapshot_type" => snapshot_type
      })

    %GlobalSectionVersion{}
    |> GlobalSectionVersion.changeset(attrs)
    |> repo.insert()
  end

  defp user_id(%User{id: id}) when is_binary(id), do: id
  defp user_id(_user), do: nil

  defp unwrap_transaction({:ok, value}), do: {:ok, value}
  defp unwrap_transaction({:error, {type, changeset}}), do: {:error, {type, changeset}}
  defp unwrap_transaction({:error, changeset}), do: {:error, changeset}
end
