defmodule MangoCMS.Tenant.ContentEngine do
  @moduledoc """
  Tenant-local flexible content engine.

  Content entries keep their full tenant-defined payload as JSON/map data while
  selected fields are projected into typed index rows for filtering and sorting.
  """

  import Ecto.Query

  alias MangoCMS.Tenant.ContentEngine.{
    ContentEntry,
    ContentEntryIndex,
    ContentType,
    ContentTypeField
  }

  alias MangoCMS.Platform.Tenant
  alias MangoCMS.Tenant.RepoManager, as: TenantRepoManager

  @default_limit 50
  @max_limit 200
  @string_index_types ~w(string text image url select)

  @doc "Lists active and archived content types for a tenant."
  @spec list_content_types(Tenant.t()) :: [ContentType.t()]
  def list_content_types(%Tenant{} = tenant) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      ContentType
      |> order_by([type], asc: type.name)
      |> repo.all()
    end)
  end

  @spec get_content_type!(Tenant.t(), String.t()) :: ContentType.t()
  def get_content_type!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get!(ContentType, id)
    end)
  end

  @spec get_content_type_by_slug(Tenant.t(), String.t()) :: ContentType.t() | nil
  def get_content_type_by_slug(%Tenant{} = tenant, slug) when is_binary(slug) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get_by(ContentType, slug: slug)
    end)
  end

  @spec create_content_type(Tenant.t(), map()) ::
          {:ok, ContentType.t()} | {:error, Ecto.Changeset.t()}
  def create_content_type(%Tenant{} = tenant, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      %ContentType{}
      |> ContentType.changeset(attrs)
      |> repo.insert()
    end)
  end

  @spec update_content_type(Tenant.t(), ContentType.t(), map()) ::
          {:ok, ContentType.t()} | {:error, Ecto.Changeset.t()}
  def update_content_type(%Tenant{} = tenant, %ContentType{} = content_type, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      content_type
      |> ContentType.changeset(attrs)
      |> repo.update()
    end)
  end

  @spec change_content_type(ContentType.t(), map()) :: Ecto.Changeset.t()
  def change_content_type(%ContentType{} = content_type, attrs \\ %{}) do
    ContentType.changeset(content_type, attrs)
  end

  @doc "Lists fields for a content type in editor/display order."
  @spec list_content_type_fields(Tenant.t(), ContentType.t() | String.t()) :: [
          ContentTypeField.t()
        ]
  def list_content_type_fields(%Tenant{} = tenant, content_type) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      content_type = resolve_content_type!(repo, content_type)
      fields_for_type(repo, content_type.id)
    end)
  end

  @spec create_content_type_field(Tenant.t(), ContentType.t(), map()) ::
          {:ok, ContentTypeField.t()} | {:error, Ecto.Changeset.t()}
  def create_content_type_field(%Tenant{} = tenant, %ContentType{} = content_type, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        case %ContentTypeField{content_type_id: content_type.id}
             |> ContentTypeField.changeset(attrs)
             |> repo.insert() do
          {:ok, field} ->
            rebuild_content_type_indexes!(repo, content_type.id)
            field

          {:error, changeset} ->
            repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec update_content_type_field(Tenant.t(), ContentTypeField.t(), map()) ::
          {:ok, ContentTypeField.t()} | {:error, Ecto.Changeset.t()}
  def update_content_type_field(%Tenant{} = tenant, %ContentTypeField{} = field, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.transaction(fn ->
        case field |> ContentTypeField.changeset(attrs) |> repo.update() do
          {:ok, field} ->
            rebuild_content_type_indexes!(repo, field.content_type_id)
            field

          {:error, changeset} ->
            repo.rollback(changeset)
        end
      end)
    end)
    |> unwrap_transaction()
  end

  @spec change_content_type_field(ContentTypeField.t(), map()) :: Ecto.Changeset.t()
  def change_content_type_field(%ContentTypeField{} = field, attrs \\ %{}) do
    ContentTypeField.changeset(field, attrs)
  end

  @doc """
  Lists entries for a content type.

  Supported opts:

    * `:status` - defaults to `"published"`, pass `"all"` for admin views
    * `:filters` - list of maps with `field`, `op`, and `value`
    * `:sort` - map or list containing `field` and `direction`
    * `:limit` - defaults to 50, capped at 200
    * `:offset` - optional offset
  """
  @spec list_entries(Tenant.t(), ContentType.t() | String.t(), keyword()) :: [ContentEntry.t()]
  def list_entries(%Tenant{} = tenant, content_type, opts \\ []) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      content_type = resolve_content_type!(repo, content_type)
      fields_by_key = fields_for_type(repo, content_type.id) |> Map.new(&{&1.field_key, &1})

      ContentEntry
      |> where([entry], entry.content_type_id == ^content_type.id and is_nil(entry.deleted_at))
      |> apply_status(opts)
      |> apply_filters(content_type.id, fields_by_key, Keyword.get(opts, :filters, []))
      |> apply_sort(content_type.id, fields_by_key, Keyword.get(opts, :sort))
      |> limit(^limit_value(opts))
      |> maybe_offset(Keyword.get(opts, :offset))
      |> repo.all()
    end)
  end

  @spec get_entry!(Tenant.t(), String.t()) :: ContentEntry.t()
  def get_entry!(%Tenant{} = tenant, id) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      repo.get!(ContentEntry, id)
    end)
  end

  @spec get_entry_by_slug(Tenant.t(), ContentType.t() | String.t(), String.t()) ::
          ContentEntry.t() | nil
  def get_entry_by_slug(%Tenant{} = tenant, content_type, slug) when is_binary(slug) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      content_type = resolve_content_type!(repo, content_type)

      repo.one(
        from entry in ContentEntry,
          where:
            entry.content_type_id == ^content_type.id and entry.slug == ^slug and
              is_nil(entry.deleted_at),
          limit: 1
      )
    end)
  end

  @spec create_entry(Tenant.t(), ContentType.t(), map()) ::
          {:ok, ContentEntry.t()} | {:error, Ecto.Changeset.t()}
  def create_entry(%Tenant{} = tenant, %ContentType{} = content_type, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      fields = fields_for_type(repo, content_type.id)

      repo.transaction(fn ->
        changeset =
          %ContentEntry{content_type_id: content_type.id}
          |> ContentEntry.changeset(attrs, fields)

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

  @spec update_entry(Tenant.t(), ContentEntry.t(), map()) ::
          {:ok, ContentEntry.t()} | {:error, Ecto.Changeset.t()}
  def update_entry(%Tenant{} = tenant, %ContentEntry{} = entry, attrs) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      fields = fields_for_type(repo, entry.content_type_id)

      repo.transaction(fn ->
        case entry |> ContentEntry.changeset(attrs, fields) |> repo.update() do
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

  @spec publish_entry(Tenant.t(), ContentEntry.t()) ::
          {:ok, ContentEntry.t()} | {:error, Ecto.Changeset.t()}
  def publish_entry(%Tenant{} = tenant, %ContentEntry{} = entry) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      fields = fields_for_type(repo, entry.content_type_id)

      repo.transaction(fn ->
        case entry |> ContentEntry.publish_changeset(fields) |> repo.update() do
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

  @spec archive_entry(Tenant.t(), ContentEntry.t()) ::
          {:ok, ContentEntry.t()} | {:error, Ecto.Changeset.t()}
  def archive_entry(%Tenant{} = tenant, %ContentEntry{} = entry) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      fields = fields_for_type(repo, entry.content_type_id)

      entry
      |> ContentEntry.archive_changeset(fields)
      |> repo.update()
    end)
  end

  @spec change_entry(ContentEntry.t(), [ContentTypeField.t()], map()) :: Ecto.Changeset.t()
  def change_entry(%ContentEntry{} = entry, fields \\ [], attrs \\ %{}) do
    ContentEntry.changeset(entry, attrs, fields)
  end

  @doc "Rebuilds all index rows for one content type."
  @spec rebuild_content_type_indexes(Tenant.t(), ContentType.t() | String.t()) :: :ok
  def rebuild_content_type_indexes(%Tenant{} = tenant, content_type) do
    TenantRepoManager.with_repo(tenant, fn repo ->
      content_type = resolve_content_type!(repo, content_type)
      rebuild_content_type_indexes!(repo, content_type.id)
    end)
  end

  defp rebuild_content_type_indexes!(repo, content_type_id) do
    fields = fields_for_type(repo, content_type_id)

    ContentEntry
    |> where([entry], entry.content_type_id == ^content_type_id)
    |> repo.all()
    |> Enum.each(&rebuild_entry_indexes!(repo, &1, fields))
  end

  defp rebuild_entry_indexes!(repo, %ContentEntry{} = entry, fields) do
    ContentEntryIndex
    |> where([index], index.content_entry_id == ^entry.id)
    |> repo.delete_all()

    entry.payload
    |> index_attrs(entry, fields)
    |> Enum.each(fn attrs ->
      %ContentEntryIndex{}
      |> ContentEntryIndex.changeset(attrs)
      |> repo.insert!()
    end)

    :ok
  end

  defp index_attrs(payload, entry, fields) do
    fields
    |> Enum.filter(&ContentTypeField.queryable?/1)
    |> Enum.flat_map(fn field ->
      value = Map.get(payload || %{}, field.field_key)

      case index_values(field, value) do
        :skip ->
          []

        values ->
          [
            Map.merge(values, %{
              content_entry_id: entry.id,
              content_type_id: entry.content_type_id,
              field_key: field.field_key,
              field_type: field.field_type
            })
          ]
      end
    end)
  end

  defp index_values(_field, value) when value in [nil, ""], do: :skip

  defp index_values(%ContentTypeField{field_type: type}, value)
       when type in @string_index_types do
    %{string_value: to_string(value)}
  end

  defp index_values(%ContentTypeField{field_type: "number"}, value) do
    case cast_float(value) do
      {:ok, number} -> %{number_value: number}
      :error -> :skip
    end
  end

  defp index_values(%ContentTypeField{field_type: "boolean"}, value) do
    case cast_boolean(value) do
      {:ok, bool} -> %{bool_value: bool}
      :error -> :skip
    end
  end

  defp index_values(%ContentTypeField{field_type: "datetime"}, value) do
    case cast_datetime(value) do
      {:ok, datetime} -> %{datetime_value: datetime}
      :error -> :skip
    end
  end

  defp index_values(_field, _value), do: :skip

  defp fields_for_type(repo, content_type_id) do
    ContentTypeField
    |> where([field], field.content_type_id == ^content_type_id)
    |> order_by([field], asc: field.position, asc: field.inserted_at)
    |> repo.all()
  end

  defp resolve_content_type!(_repo, %ContentType{id: id} = content_type) when is_binary(id) do
    content_type
  end

  defp resolve_content_type!(repo, id_or_slug) when is_binary(id_or_slug) do
    repo.get(ContentType, id_or_slug) || repo.get_by!(ContentType, slug: id_or_slug)
  end

  defp apply_status(query, opts) do
    case Keyword.get(opts, :status, "published") do
      "all" -> query
      :all -> query
      status when is_binary(status) -> where(query, [entry], entry.status == ^status)
      _other -> where(query, [entry], entry.status == "published")
    end
  end

  defp apply_filters(query, _content_type_id, _fields_by_key, nil), do: query
  defp apply_filters(query, _content_type_id, _fields_by_key, []), do: query

  defp apply_filters(query, content_type_id, fields_by_key, filters) when is_list(filters) do
    Enum.reduce(filters, query, fn filter, acc ->
      apply_filter(acc, content_type_id, fields_by_key, filter)
    end)
  end

  defp apply_filters(query, content_type_id, fields_by_key, filter) when is_map(filter) do
    apply_filter(query, content_type_id, fields_by_key, filter)
  end

  defp apply_filter(query, content_type_id, fields_by_key, filter) do
    with field_key when is_binary(field_key) <- filter_value(filter, :field),
         %ContentTypeField{} = field <- Map.get(fields_by_key, field_key),
         true <- ContentTypeField.queryable?(field),
         {:ok, value} <- comparable_value(field, filter_value(filter, :value)) do
      op = filter_value(filter, :op) || "=="

      index_query =
        content_type_id
        |> base_index_query(field)
        |> apply_index_operator(field, op, value)

      where(query, [entry], entry.id in subquery(index_query))
    else
      _not_filterable -> query
    end
  end

  defp base_index_query(content_type_id, field) do
    from index in ContentEntryIndex,
      where: index.content_type_id == ^content_type_id and index.field_key == ^field.field_key,
      select: index.content_entry_id
  end

  defp apply_index_operator(query, %ContentTypeField{} = field, op, value) do
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

  defp apply_sort(query, _content_type_id, _fields_by_key, nil) do
    order_by(query, [entry], desc: entry.inserted_at)
  end

  defp apply_sort(query, content_type_id, fields_by_key, sort) when is_list(sort) do
    sort
    |> List.first()
    |> then(&apply_sort(query, content_type_id, fields_by_key, &1))
  end

  defp apply_sort(query, content_type_id, fields_by_key, sort) when is_map(sort) do
    field_key = filter_value(sort, :field)
    direction = sort_direction(filter_value(sort, :direction))

    if field_key in ["inserted_at", "published_at", "title"] do
      apply_entry_sort(query, field_key, direction)
    else
      case Map.get(fields_by_key, field_key) do
        %ContentTypeField{} = field ->
          if ContentTypeField.queryable?(field) do
            apply_index_sort(query, content_type_id, field, direction)
          else
            order_by(query, [entry], desc: entry.inserted_at)
          end

        _field ->
          order_by(query, [entry], desc: entry.inserted_at)
      end
    end
  end

  defp apply_sort(query, _content_type_id, _fields_by_key, _sort) do
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

  defp apply_index_sort(query, content_type_id, field, :asc) do
    column = index_column(field)

    from entry in query,
      join: index in ContentEntryIndex,
      on:
        index.content_entry_id == entry.id and index.content_type_id == ^content_type_id and
          index.field_key == ^field.field_key,
      order_by: [asc: field(index, ^column)]
  end

  defp apply_index_sort(query, content_type_id, field, :desc) do
    column = index_column(field)

    from entry in query,
      join: index in ContentEntryIndex,
      on:
        index.content_entry_id == entry.id and index.content_type_id == ^content_type_id and
          index.field_key == ^field.field_key,
      order_by: [desc: field(index, ^column)]
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

  defp comparable_value(%ContentTypeField{} = field, value) do
    case index_values(field, value) do
      %{string_value: value} -> {:ok, value}
      %{number_value: value} -> {:ok, value}
      %{bool_value: value} -> {:ok, value}
      %{datetime_value: value} -> {:ok, value}
      :skip -> :error
    end
  end

  defp index_column(%ContentTypeField{field_type: type}) when type in @string_index_types,
    do: :string_value

  defp index_column(%ContentTypeField{field_type: "number"}), do: :number_value
  defp index_column(%ContentTypeField{field_type: "boolean"}), do: :bool_value
  defp index_column(%ContentTypeField{field_type: "datetime"}), do: :datetime_value
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

  defp unwrap_transaction({:ok, result}), do: {:ok, result}
  defp unwrap_transaction({:error, reason}), do: {:error, reason}
end
