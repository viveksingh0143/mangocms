defmodule MangoCMS.TenantCatalog do
  @moduledoc """
  Tenant-local catalog operations.

  Each function runs against the SQLite database attached to the given tenant.
  """

  import Ecto.Query

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.TenantCatalog.Product
  alias MangoCMS.TenantRepoManager

  @doc "Lists products from the tenant's isolated database."
  @spec list_products(Tenant.t()) :: [Product.t()]
  def list_products(%Tenant{} = tenant) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      Product
      |> order_by([p], desc: p.inserted_at)
      |> repo.all()
    end)
  end

  @doc "Fetches a product from the tenant's isolated database."
  @spec get_product!(Tenant.t(), String.t()) :: Product.t()
  def get_product!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get!(Product, id)
    end)
  end

  @doc "Creates a product in the tenant's isolated database."
  @spec create_product(Tenant.t(), map()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def create_product(%Tenant{} = tenant, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %Product{}
      |> Product.changeset(attrs)
      |> repo.insert()
    end)
  end

  @doc "Updates a product in the tenant's isolated database."
  @spec update_product(Tenant.t(), Product.t(), map()) ::
          {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def update_product(%Tenant{} = tenant, %Product{} = product, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      product
      |> Product.changeset(attrs)
      |> repo.update()
    end)
  end

  @doc "Deletes a product from the tenant's isolated database."
  @spec delete_product(Tenant.t(), Product.t()) ::
          {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def delete_product(%Tenant{} = tenant, %Product{} = product) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.delete(product)
    end)
  end

  @doc "Returns a changeset for tracking product changes."
  @spec change_product(Product.t(), map()) :: Ecto.Changeset.t()
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
