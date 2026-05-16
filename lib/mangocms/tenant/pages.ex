defmodule MangoCMS.Tenant.Pages do
  @moduledoc "Tenant-local pages and reusable sections."

  import Ecto.Query

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.Accounts.User

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
