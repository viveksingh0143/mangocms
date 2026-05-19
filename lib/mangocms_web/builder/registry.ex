defmodule MangoCMSWeb.Builder.Registry do
  @moduledoc """
  Registry for MangoCMS builder component manifests.

  The registry intentionally loads Elixir manifest modules instead of reading
  JSON files, keeping component definitions refactorable and testable.
  """

  alias MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Manifests

  @manifest_modules [
    Manifests.Button,
    Manifests.Card,
    Manifests.Hero,
    Manifests.Modal,
    Manifests.Dropdown,
    Manifests.Fab,
    Manifests.Swap,
    Manifests.ThemeController,
    Manifests.Alert,
    Manifests.Loading,
    Manifests.Progress,
    Manifests.RadialProgress,
    Manifests.Skeleton,
    Manifests.Toast,
    Manifests.Tooltip,
    Manifests.Divider,
    Manifests.Drawer,
    Manifests.Footer,
    Manifests.Indicator,
    Manifests.Join,
    Manifests.Mask,
    Manifests.Stack,
    Manifests.Breadcrumbs,
    Manifests.Dock,
    Manifests.Link,
    Manifests.Menu,
    Manifests.Navbar,
    Manifests.Pagination,
    Manifests.Steps,
    Manifests.Carousel,
    Manifests.Tabs,
    Manifests.Input
  ]

  @doc "Returns manifest modules loaded by the registry."
  @spec manifest_modules() :: [module()]
  def manifest_modules, do: @manifest_modules

  @doc "Returns all normalized component manifests."
  @spec all() :: [Manifest.t()]
  def all do
    Enum.map(@manifest_modules, fn module ->
      module.manifest()
      |> Manifest.normalize()
    end)
  end

  @doc "Finds a manifest by component name."
  @spec get(String.t()) :: Manifest.t() | nil
  def get(name) when is_binary(name), do: Enum.find(all(), &(&1.name == name))

  @doc "Finds a manifest by component name or raises."
  @spec get!(String.t()) :: Manifest.t()
  def get!(name) when is_binary(name) do
    get(name) || raise ArgumentError, "unknown builder component manifest: #{name}"
  end

  @doc "Returns the selected variant for a component name or manifest."
  @spec variant(String.t() | Manifest.t(), String.t() | nil) :: Manifest.variant() | nil
  def variant(component_or_manifest, variant_id)

  def variant(name, variant_id) when is_binary(name), do: name |> get!() |> variant(variant_id)

  def variant(manifest, nil) when is_map(manifest),
    do: variant(manifest, manifest.default_variant)

  def variant(manifest, variant_id) when is_map(manifest) and is_binary(variant_id) do
    Enum.find(manifest.variants, &(&1.id == variant_id))
  end

  @doc "Returns fields exposed for the given component variant."
  @spec fields_for_variant(String.t() | Manifest.t(), String.t() | nil) :: [
          MangoCMSWeb.Builder.Field.t()
        ]
  def fields_for_variant(component_or_manifest, variant_id \\ nil)

  def fields_for_variant(name, variant_id) when is_binary(name) do
    name
    |> get!()
    |> fields_for_variant(variant_id)
  end

  def fields_for_variant(manifest, variant_id) when is_map(manifest) do
    variant = variant(manifest, variant_id) || variant(manifest, nil)
    field_keys = Map.get(variant || %{}, :fields, Map.keys(manifest.fields))

    field_keys
    |> Enum.map(&Map.get(manifest.fields, &1))
    |> Enum.reject(&is_nil/1)
  end

  @doc "Returns slot definitions exposed for the given component variant."
  @spec slots_for_variant(String.t() | Manifest.t(), String.t() | nil) :: [Manifest.slot()]
  def slots_for_variant(component_or_manifest, variant_id \\ nil)

  def slots_for_variant(name, variant_id) when is_binary(name) do
    name
    |> get!()
    |> slots_for_variant(variant_id)
  end

  def slots_for_variant(manifest, variant_id) when is_map(manifest) do
    variant = variant(manifest, variant_id) || variant(manifest, nil)
    slot_ids = Map.get(variant || %{}, :slots, Enum.map(manifest.slots, & &1.id))

    Enum.filter(manifest.slots, &(&1.id in slot_ids))
  end

  @doc "Creates a content-tree compatible node from manifest defaults."
  @spec default_node(String.t(), String.t() | nil) :: map()
  def default_node(name, variant_id \\ nil) when is_binary(name) do
    manifest = get!(name)
    variant = variant(manifest, variant_id) || variant(manifest, nil)
    variant_id = Map.get(variant || %{}, :id, manifest.default_variant)

    props =
      manifest.default_props
      |> Map.merge(Map.get(variant || %{}, :default_props, %{}))

    classes =
      manifest.default_classes
      |> Map.merge(Map.get(variant || %{}, :default_classes, %{}))

    %{
      "type" => "component",
      "name" => manifest.name,
      "variant" => variant_id,
      "id" => unique_id(manifest.name),
      "path" => "root",
      "props" => props,
      "classes" => classes,
      "slots" => empty_slots(manifest, variant_id),
      "children" => []
    }
  end

  @doc "Returns example nodes declared by a manifest, one per variant where possible."
  @spec examples(String.t() | Manifest.t()) :: [map()]
  def examples(name) when is_binary(name), do: name |> get!() |> examples()

  def examples(manifest) when is_map(manifest) do
    Enum.map(manifest.examples, fn example ->
      node = default_node(manifest.name, example.variant)

      node
      |> put_in(["props"], Map.merge(node["props"], Map.get(example, :props, %{})))
      |> put_in(["classes"], Map.merge(node["classes"], Map.get(example, :classes, %{})))
    end)
  end

  defp empty_slots(manifest, variant_id) do
    manifest
    |> slots_for_variant(variant_id)
    |> Map.new(&{&1.id, []})
  end

  defp unique_id(name), do: "#{name}_#{System.unique_integer([:positive])}"
end
