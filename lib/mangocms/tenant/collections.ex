defmodule MangoCMS.Tenant.Collections do
  @moduledoc """
  Tenant-local flexible collections system.

  Collection items keep their full tenant-defined payload as JSON/map data while
  selected fields are projected into typed index rows for filtering and sorting.
  """

  import Ecto.Query

  alias MangoCMS.Tenant.Collections.{
    CollectionItem,
    CollectionItemIndex,
    Collection,
    CollectionField
  }

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.RepoManager, as: TenantRepoManager

  @default_limit 50
  @max_limit 200
  @string_index_types ~w(string text rich_text rich_content image video audio document asset url email color time address category reference select)

  @doc "Lists active and archived collections for a tenant."
  @spec list_collections(Tenant.t()) :: [Collection.t()]
  def list_collections(%Tenant{} = tenant) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      Collection
      |> order_by([type], asc: type.name)
      |> repo.all()
    end)
  end

  @doc "Returns active, non-deleted item counts keyed by collection id."
  @spec collection_entry_counts(Tenant.t()) :: %{String.t() => non_neg_integer()}
  def collection_entry_counts(%Tenant{} = tenant) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      CollectionItem
      |> where([entry], is_nil(entry.deleted_at))
      |> group_by([entry], entry.collection_id)
      |> select([entry], {entry.collection_id, count(entry.id)})
      |> repo.all()
      |> Map.new()
    end)
  end

  @spec get_collection!(Tenant.t(), String.t()) :: Collection.t()
  def get_collection!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get!(Collection, id)
    end)
  end

  @spec get_collection_by_slug(Tenant.t(), String.t()) :: Collection.t() | nil
  def get_collection_by_slug(%Tenant{} = tenant, slug) when is_binary(slug) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get_by(Collection, slug: slug)
    end)
  end

  @spec delete_collection(Tenant.t(), Collection.t()) ::
          {:ok, Collection.t()} | {:error, Ecto.Changeset.t()}
  def delete_collection(%Tenant{} = tenant, %Collection{} = collection) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.delete(collection)
    end)
  end

  @spec create_collection(Tenant.t(), map()) ::
          {:ok, Collection.t()} | {:error, Ecto.Changeset.t()}
  def create_collection(%Tenant{} = tenant, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %Collection{}
      |> Collection.changeset(attrs)
      |> repo.insert()
    end)
  end

  @spec update_collection(Tenant.t(), Collection.t(), map()) ::
          {:ok, Collection.t()} | {:error, Ecto.Changeset.t()}
  def update_collection(%Tenant{} = tenant, %Collection{} = collection, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      collection
      |> Collection.changeset(attrs)
      |> repo.update()
    end)
  end

  @spec change_collection(Collection.t(), map()) :: Ecto.Changeset.t()
  def change_collection(%Collection{} = collection, attrs \\ %{}) do
    Collection.changeset(collection, attrs)
  end

  @doc "Lists fields for a collection in editor/display order."
  @spec list_collection_fields(Tenant.t(), Collection.t() | String.t()) :: [
          CollectionField.t()
        ]
  def list_collection_fields(%Tenant{} = tenant, collection) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      collection = resolve_collection!(repo, collection)
      fields_for_type(repo, collection.id)
    end)
  end

  @spec get_collection_field!(Tenant.t(), String.t()) :: CollectionField.t()
  def get_collection_field!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get!(CollectionField, id)
    end)
  end

  @spec create_collection_field(Tenant.t(), Collection.t(), map()) ::
          {:ok, CollectionField.t()} | {:error, Ecto.Changeset.t()}
  def create_collection_field(%Tenant{} = tenant, %Collection{} = collection, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        case %CollectionField{collection_id: collection.id}
             |> CollectionField.changeset(attrs)
             |> repo.insert() do
          {:ok, field} ->
            rebuild_collection_indexes!(repo, collection.id)
            field

          {:error, changeset} ->
            repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec update_collection_field(Tenant.t(), CollectionField.t(), map()) ::
          {:ok, CollectionField.t()} | {:error, Ecto.Changeset.t()}
  def update_collection_field(%Tenant{} = tenant, %CollectionField{} = field, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        case field |> CollectionField.changeset(attrs) |> repo.update() do
          {:ok, field} ->
            rebuild_collection_indexes!(repo, field.collection_id)
            field

          {:error, changeset} ->
            repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec delete_collection_field(Tenant.t(), CollectionField.t()) ::
          {:ok, CollectionField.t()} | {:error, Ecto.Changeset.t()}
  def delete_collection_field(%Tenant{} = tenant, %CollectionField{} = field) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        case repo.delete(field) do
          {:ok, field} ->
            rebuild_collection_indexes!(repo, field.collection_id)
            field

          {:error, changeset} ->
            repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec change_collection_field(CollectionField.t(), map()) :: Ecto.Changeset.t()
  def change_collection_field(%CollectionField{} = field, attrs \\ %{}) do
    CollectionField.changeset(field, attrs)
  end

  @doc """
  Lists entries for a collection.

  Supported opts:

    * `:status` - defaults to `"published"`, pass `"all"` for admin views
    * `:filters` - list of maps with `field`, `op`, and `value`
    * `:sort` - map or list containing `field` and `direction`
    * `:limit` - defaults to 50, capped at 200
    * `:offset` - optional offset
  """
  @spec list_entries(Tenant.t(), Collection.t() | String.t(), keyword()) :: [CollectionItem.t()]
  def list_entries(%Tenant{} = tenant, collection, opts \\ []) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      collection = resolve_collection!(repo, collection)
      fields_by_key = fields_for_type(repo, collection.id) |> Map.new(&{&1.field_key, &1})

      CollectionItem
      |> where([entry], entry.collection_id == ^collection.id and is_nil(entry.deleted_at))
      |> apply_status(opts)
      |> apply_filters(collection.id, fields_by_key, Keyword.get(opts, :filters, []))
      |> apply_sort(collection.id, fields_by_key, Keyword.get(opts, :sort))
      |> limit(^limit_value(opts))
      |> maybe_offset(Keyword.get(opts, :offset))
      |> repo.all()
    end)
  end

  @spec get_entry!(Tenant.t(), String.t()) :: CollectionItem.t()
  def get_entry!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get!(CollectionItem, id)
    end)
  end

  @spec get_entry_by_slug(Tenant.t(), Collection.t() | String.t(), String.t()) ::
          CollectionItem.t() | nil
  def get_entry_by_slug(%Tenant{} = tenant, collection, slug) when is_binary(slug) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      collection = resolve_collection!(repo, collection)

      repo.one(
        from(entry in CollectionItem,
          where:
            entry.collection_id == ^collection.id and entry.slug == ^slug and
              is_nil(entry.deleted_at),
          limit: 1
        )
      )
    end)
  end

  @spec create_entry(Tenant.t(), Collection.t(), map(), keyword()) ::
          {:ok, CollectionItem.t()} | {:error, Ecto.Changeset.t()}
  @spec create_entry(Tenant.t(), Collection.t(), map()) ::
          {:ok, CollectionItem.t()} | {:error, Ecto.Changeset.t()}
  def create_entry(%Tenant{} = tenant, %Collection{} = collection, attrs, opts \\ []) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      fields = fields_for_type(repo, collection.id)
      owner_id = Keyword.get(opts, :owner_id)

      repo.transaction(fn ->
        changeset =
          %CollectionItem{collection_id: collection.id, owner_id: owner_id}
          |> CollectionItem.changeset(attrs, fields)
          |> validate_unique_payload_fields(repo, collection.id, fields, nil)

        case repo.insert(changeset) do
          {:ok, entry} ->
            rebuild_entry_indexes!(repo, entry, fields)
            entry

          {:error, changeset} ->
            repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec update_entry(Tenant.t(), CollectionItem.t(), map()) ::
          {:ok, CollectionItem.t()} | {:error, Ecto.Changeset.t()}
  def update_entry(%Tenant{} = tenant, %CollectionItem{} = entry, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      fields = fields_for_type(repo, entry.collection_id)

      repo.transaction(fn ->
        changeset =
          entry
          |> CollectionItem.changeset(attrs, fields)
          |> validate_unique_payload_fields(repo, entry.collection_id, fields, entry.id)

        case repo.update(changeset) do
          {:ok, entry} ->
            rebuild_entry_indexes!(repo, entry, fields)
            entry

          {:error, changeset} ->
            repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec publish_entry(Tenant.t(), CollectionItem.t()) ::
          {:ok, CollectionItem.t()} | {:error, Ecto.Changeset.t()}
  def publish_entry(%Tenant{} = tenant, %CollectionItem{} = entry) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      fields = fields_for_type(repo, entry.collection_id)

      repo.transaction(fn ->
        case entry |> CollectionItem.publish_changeset(fields) |> repo.update() do
          {:ok, entry} ->
            rebuild_entry_indexes!(repo, entry, fields)
            entry

          {:error, changeset} ->
            repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec archive_entry(Tenant.t(), CollectionItem.t()) ::
          {:ok, CollectionItem.t()} | {:error, Ecto.Changeset.t()}
  def archive_entry(%Tenant{} = tenant, %CollectionItem{} = entry) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      fields = fields_for_type(repo, entry.collection_id)

      entry
      |> CollectionItem.archive_changeset(fields)
      |> repo.update()
    end)
  end

  @spec delete_entry(Tenant.t(), CollectionItem.t()) ::
          {:ok, CollectionItem.t()} | {:error, Ecto.Changeset.t()}
  def delete_entry(%Tenant{} = tenant, %CollectionItem{} = entry) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.delete(entry)
    end)
  end

  @spec change_entry(CollectionItem.t(), [CollectionField.t()], map()) :: Ecto.Changeset.t()
  def change_entry(%CollectionItem{} = entry, fields \\ [], attrs \\ %{}) do
    CollectionItem.changeset(entry, attrs, fields)
  end

  @doc "Rebuilds all index rows for one collection."
  @spec rebuild_collection_indexes(Tenant.t(), Collection.t() | String.t()) :: :ok
  def rebuild_collection_indexes(%Tenant{} = tenant, collection) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      collection = resolve_collection!(repo, collection)
      rebuild_collection_indexes!(repo, collection.id)
    end)
  end

  defp rebuild_collection_indexes!(repo, collection_id) do
    fields = fields_for_type(repo, collection_id)

    CollectionItem
    |> where([entry], entry.collection_id == ^collection_id)
    |> repo.all()
    |> Enum.each(&rebuild_entry_indexes!(repo, &1, fields))
  end

  defp rebuild_entry_indexes!(repo, %CollectionItem{} = entry, fields) do
    CollectionItemIndex
    |> where([index], index.collection_item_id == ^entry.id)
    |> repo.delete_all()

    entry.payload
    |> index_attrs(entry, fields)
    |> Enum.each(fn attrs ->
      %CollectionItemIndex{}
      |> CollectionItemIndex.changeset(attrs)
      |> repo.insert!()
    end)

    :ok
  end

  defp index_attrs(payload, entry, fields) do
    fields
    |> Enum.filter(&CollectionField.queryable?/1)
    |> Enum.flat_map(fn field ->
      value = Map.get(payload || %{}, field.field_key)

      case index_values(field, value) do
        :skip ->
          []

        values ->
          [
            Map.merge(values, %{
              collection_item_id: entry.id,
              collection_id: entry.collection_id,
              field_key: field.field_key,
              field_type: field.field_type
            })
          ]
      end
    end)
  end

  defp index_values(_field, value) when value in [nil, ""], do: :skip

  defp index_values(%CollectionField{field_type: type}, value)
       when type in @string_index_types do
    %{string_value: to_string(value)}
  end

  defp index_values(%CollectionField{field_type: "number"}, value) do
    case cast_float(value) do
      {:ok, number} -> %{number_value: number}
      :error -> :skip
    end
  end

  defp index_values(%CollectionField{field_type: "boolean"}, value) do
    case cast_boolean(value) do
      {:ok, bool} -> %{bool_value: bool}
      :error -> :skip
    end
  end

  defp index_values(%CollectionField{field_type: "datetime"}, value) do
    case cast_datetime(value) do
      {:ok, datetime} -> %{datetime_value: datetime}
      :error -> :skip
    end
  end

  defp index_values(_field, _value), do: :skip

  defp validate_unique_payload_fields(changeset, repo, collection_id, fields, current_entry_id) do
    if changeset.valid? do
      payload = Ecto.Changeset.get_field(changeset, :payload) || %{}

      Enum.reduce(unique_fields(fields), changeset, fn field, changeset ->
        value = Map.get(payload, field.field_key)

        if unique_conflict?(repo, collection_id, field, value, current_entry_id) do
          Ecto.Changeset.add_error(
            changeset,
            :payload,
            "#{field.field_key} must be unique"
          )
        else
          changeset
        end
      end)
    else
      changeset
    end
  end

  defp unique_fields(fields) do
    Enum.filter(fields, fn field ->
      field.unique == true and CollectionField.queryable?(field)
    end)
  end

  defp unique_conflict?(_repo, _collection_id, _field, value, _current_entry_id)
       when value in [nil, "", []],
       do: false

  defp unique_conflict?(repo, collection_id, field, value, current_entry_id) do
    case comparable_value(field, value) do
      {:ok, comparable} ->
        column = index_column(field)

        query =
          from(index in CollectionItemIndex,
            join: entry in CollectionItem,
            on: entry.id == index.collection_item_id,
            where:
              index.collection_id == ^collection_id and index.field_key == ^field.field_key and
                field(index, ^column) == ^comparable and is_nil(entry.deleted_at),
            select: index.collection_item_id,
            limit: 1
          )

        query =
          if is_binary(current_entry_id) do
            where(query, [index, _entry], index.collection_item_id != ^current_entry_id)
          else
            query
          end

        repo.exists?(query)

      :error ->
        false
    end
  end

  defp fields_for_type(repo, collection_id) do
    CollectionField
    |> where([field], field.collection_id == ^collection_id)
    |> order_by([field], asc: field.position, asc: field.inserted_at)
    |> repo.all()
  end

  defp resolve_collection!(_repo, %Collection{id: id} = collection) when is_binary(id) do
    collection
  end

  defp resolve_collection!(repo, id_or_slug) when is_binary(id_or_slug) do
    repo.get(Collection, id_or_slug) || repo.get_by!(Collection, slug: id_or_slug)
  end

  defp apply_status(query, opts) do
    case Keyword.get(opts, :status, "published") do
      "all" -> query
      :all -> query
      status when is_binary(status) -> where(query, [entry], entry.status == ^status)
      _other -> where(query, [entry], entry.status == "published")
    end
  end

  defp apply_filters(query, _collection_id, _fields_by_key, nil), do: query
  defp apply_filters(query, _collection_id, _fields_by_key, []), do: query

  defp apply_filters(query, collection_id, fields_by_key, filters) when is_list(filters) do
    Enum.reduce(filters, query, fn filter, acc ->
      apply_filter(acc, collection_id, fields_by_key, filter)
    end)
  end

  defp apply_filters(query, collection_id, fields_by_key, filter) when is_map(filter) do
    apply_filter(query, collection_id, fields_by_key, filter)
  end

  defp apply_filter(query, collection_id, fields_by_key, filter) do
    with field_key when is_binary(field_key) <- filter_value(filter, :field),
         %CollectionField{} = field <- Map.get(fields_by_key, field_key),
         true <- CollectionField.queryable?(field),
         {:ok, value} <- comparable_value(field, filter_value(filter, :value)) do
      op = filter_value(filter, :op) || "=="

      index_query =
        collection_id
        |> base_index_query(field)
        |> apply_index_operator(field, op, value)

      where(query, [entry], entry.id in subquery(index_query))
    else
      _not_filterable -> query
    end
  end

  defp base_index_query(collection_id, field) do
    from(index in CollectionItemIndex,
      where: index.collection_id == ^collection_id and index.field_key == ^field.field_key,
      select: index.collection_item_id
    )
  end

  defp apply_index_operator(query, %CollectionField{} = field, op, value) do
    column = index_column(field)

    case normalize_operator(op) do
      :eq ->
        where(query, [index], field(index, ^column) == ^value)

      :not_eq ->
        where(query, [index], field(index, ^column) != ^value)

      :gt ->
        where(query, [index], field(index, ^column) > ^value)

      :gte ->
        where(query, [index], field(index, ^column) >= ^value)

      :lt ->
        where(query, [index], field(index, ^column) < ^value)

      :lte ->
        where(query, [index], field(index, ^column) <= ^value)

      :contains when column == :string_value ->
        where(query, [index], like(index.string_value, ^"%#{value}%"))

      _unsupported ->
        where(query, [index], field(index, ^column) == ^value)
    end
  end

  defp apply_sort(query, _collection_id, _fields_by_key, nil) do
    order_by(query, [entry], desc: entry.inserted_at)
  end

  defp apply_sort(query, collection_id, fields_by_key, sort) when is_list(sort) do
    sort
    |> List.first()
    |> then(&apply_sort(query, collection_id, fields_by_key, &1))
  end

  defp apply_sort(query, collection_id, fields_by_key, sort) when is_map(sort) do
    field_key = filter_value(sort, :field)
    direction = sort_direction(filter_value(sort, :direction))

    if field_key in ["inserted_at", "published_at", "title"] do
      apply_entry_sort(query, field_key, direction)
    else
      case Map.get(fields_by_key, field_key) do
        %CollectionField{} = field ->
          if CollectionField.queryable?(field) do
            apply_index_sort(query, collection_id, field, direction)
          else
            order_by(query, [entry], desc: entry.inserted_at)
          end

        _field ->
          order_by(query, [entry], desc: entry.inserted_at)
      end
    end
  end

  defp apply_sort(query, _collection_id, _fields_by_key, _sort) do
    order_by(query, [entry], desc: entry.inserted_at)
  end

  defp apply_entry_sort(query, field_key, :asc) do
    field = String.to_existing_atom(field_key)
    order_by(query, [entry], asc: field(entry, ^field))
  end

  defp apply_entry_sort(query, field_key, :desc) do
    field = String.to_existing_atom(field_key)
    order_by(query, [entry], desc: field(entry, ^field))
  end

  defp apply_index_sort(query, collection_id, field, :asc) do
    column = index_column(field)

    from(entry in query,
      join: index in CollectionItemIndex,
      on:
        index.collection_item_id == entry.id and index.collection_id == ^collection_id and
          index.field_key == ^field.field_key,
      order_by: [asc: field(index, ^column)]
    )
  end

  defp apply_index_sort(query, collection_id, field, :desc) do
    column = index_column(field)

    from(entry in query,
      join: index in CollectionItemIndex,
      on:
        index.collection_item_id == entry.id and index.collection_id == ^collection_id and
          index.field_key == ^field.field_key,
      order_by: [desc: field(index, ^column)]
    )
  end

  defp maybe_offset(query, nil), do: query

  defp maybe_offset(query, offset) when is_integer(offset) and offset >= 0,
    do: offset(query, ^offset)

  defp maybe_offset(query, _offset), do: query

  defp limit_value(opts) do
    opts
    |> Keyword.get(:limit, @default_limit)
    |> case do
      limit when is_integer(limit) and limit > 0 -> min(limit, @max_limit)
      _other -> @default_limit
    end
  end

  defp filter_value(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp filter_value(_other, _key), do: nil

  defp comparable_value(%CollectionField{} = field, value) do
    case index_values(field, value) do
      %{string_value: value} -> {:ok, value}
      %{number_value: value} -> {:ok, value}
      %{bool_value: value} -> {:ok, value}
      %{datetime_value: value} -> {:ok, value}
      :skip -> :error
    end
  end

  defp index_column(%CollectionField{field_type: type}) when type in @string_index_types,
    do: :string_value

  defp index_column(%CollectionField{field_type: "number"}), do: :number_value
  defp index_column(%CollectionField{field_type: "boolean"}), do: :bool_value
  defp index_column(%CollectionField{field_type: "datetime"}), do: :datetime_value
  defp index_column(_field), do: :string_value

  defp normalize_operator(op) when op in ["==", "=", :==, :eq], do: :eq
  defp normalize_operator(op) when op in ["!=", "<>", :!=, :not_eq], do: :not_eq
  defp normalize_operator(op) when op in [">", :>, :gt], do: :gt
  defp normalize_operator(op) when op in [">=", :>=, :gte], do: :gte
  defp normalize_operator(op) when op in ["<", :<, :lt], do: :lt
  defp normalize_operator(op) when op in ["<=", :<=, :lte], do: :lte
  defp normalize_operator(op) when op in ["contains", :contains], do: :contains
  defp normalize_operator(_op), do: :eq

  defp sort_direction(direction) when direction in ["asc", "ASC", :asc], do: :asc
  defp sort_direction(_direction), do: :desc

  defp cast_float(value) when is_integer(value), do: {:ok, value / 1}
  defp cast_float(value) when is_float(value), do: {:ok, value}

  defp cast_float(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> {:ok, number}
      _other -> :error
    end
  end

  defp cast_float(_value), do: :error

  defp cast_boolean(value) when is_boolean(value), do: {:ok, value}
  defp cast_boolean(value) when value in ["true", "1"], do: {:ok, true}
  defp cast_boolean(value) when value in ["false", "0"], do: {:ok, false}
  defp cast_boolean(_value), do: :error

  defp cast_datetime(%DateTime{} = value), do: {:ok, DateTime.truncate(value, :second)}

  defp cast_datetime(%NaiveDateTime{} = value) do
    {:ok, value |> DateTime.from_naive!("Etc/UTC") |> DateTime.truncate(:second)}
  end

  defp cast_datetime(%Date{} = value) do
    datetime =
      value
      |> NaiveDateTime.new!(~T[00:00:00])
      |> DateTime.from_naive!("Etc/UTC")

    {:ok, datetime}
  end

  defp cast_datetime(value) when is_binary(value) do
    value = normalize_datetime_input(value)

    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        {:ok, DateTime.truncate(datetime, :second)}

      {:error, _reason} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive} -> cast_datetime(naive)
          {:error, _reason} -> :error
        end
    end
  end

  defp cast_datetime(_value), do: :error

  defp normalize_datetime_input(value) do
    value = String.trim(value)

    cond do
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/, value) ->
        value <> ":00"

      true ->
        value
    end
  end

  defp unwrap_transaction({:ok, result}), do: {:ok, result}
  defp unwrap_transaction({:error, reason}), do: {:error, reason}
end
