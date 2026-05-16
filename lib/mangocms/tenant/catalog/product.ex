defmodule MangoCMS.Tenant.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @timestamps_opts [type: :utc_datetime]

  @valid_statuses ~w(draft active archived)
  @valid_currencies ~w(INR USD EUR GBP AUD SGD)
  @required_fields ~w(name slug status price currency)a
  @optional_fields ~w(sku description custom_fields stock_quantity active)a

  @type t :: %__MODULE__{}

  schema "products" do
    field(:name, :string)
    field(:slug, :string)
    field(:sku, :string)
    field(:description, :string)
    field(:custom_fields, :map, default: %{})
    field(:status, :string, default: "draft")
    field(:price, :integer, default: 0)
    field(:currency, :string, default: "INR")
    field(:stock_quantity, :integer, default: 0)
    field(:active, :boolean, default: true)

    timestamps()
  end

  @doc "Builds a product changeset for a tenant-local product."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(product, attrs) do
    product
    |> ensure_id()
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> normalize_map(:custom_fields)
    |> maybe_put_slug()
    |> normalize_change(:slug, &slugify/1)
    |> normalize_change(:sku, &String.trim/1)
    |> blank_to_nil(:sku)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 2, max: 120)
    |> validate_length(:slug, min: 2, max: 120)
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/,
      message: "only lowercase letters, numbers, underscores and hyphens"
    )
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:currency, @valid_currencies)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_number(:stock_quantity, greater_than_or_equal_to: 0)
    |> unique_constraint(:slug, name: :products_slug_index)
    |> unique_constraint(:sku, name: :products_sku_index)
  end

  defp ensure_id(%__MODULE__{id: nil} = product), do: %{product | id: Ecto.UUID.generate()}
  defp ensure_id(product), do: product

  defp maybe_put_slug(changeset) do
    slug = get_field(changeset, :slug)
    name = get_field(changeset, :name)

    if blank?(slug) and is_binary(name) do
      put_change(changeset, :slug, slugify(name))
    else
      changeset
    end
  end

  defp normalize_change(changeset, field, normalizer) do
    case get_change(changeset, field) do
      value when is_binary(value) -> put_change(changeset, field, normalizer.(value))
      _ -> changeset
    end
  end

  defp blank_to_nil(changeset, field) do
    if blank?(get_change(changeset, field)) do
      put_change(changeset, field, nil)
    else
      changeset
    end
  end

  defp normalize_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      _other -> put_change(changeset, field, %{})
    end
  end

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9_-]+/, "-")
    |> String.trim("-")
  end

  defp blank?(value), do: value in [nil, ""]
end
