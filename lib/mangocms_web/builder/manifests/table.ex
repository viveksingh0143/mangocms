defmodule MangoCMSWeb.Builder.Manifests.Table do
  @moduledoc "Builder manifest for collection-friendly tables."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "table",
      label: "Table",
      group: "Data display",
      icon: "hero-table-cells",
      renderer: {DisplayComponents, :table},
      default_variant: "standard",
      accepted_children: ["link", "button", "badge", "image"],
      default_props: %{
        "collection" => "",
        "zebra" => true,
        "size" => "md",
        "columns" => [
          %{"label" => "Name", "field" => "title"},
          %{"label" => "Status", "field" => "status"},
          %{"label" => "Updated", "field" => "updated_at"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "header", label: "Header", accepts: ["heading", "button"]},
        %{id: "rows", label: "Rows", accepts: ["link", "button", "badge", "image"]}
      ],
      variants: [
        %{
          id: "standard",
          label: "Standard",
          description: "Responsive data table",
          fields: [:collection, :columns, :zebra, :size, :classes, :slots],
          slots: ["header", "rows"]
        },
        %{
          id: "compact",
          label: "Compact",
          description: "Small dense table",
          default_props: %{"size" => "sm"},
          fields: [:collection, :columns, :zebra, :size, :classes, :slots],
          slots: ["header", "rows"]
        }
      ],
      examples: [
        %{variant: "standard", props: %{}},
        %{variant: "compact", props: %{"size" => "sm"}}
      ],
      fields: %{
        collection: Field.text("collection", label: "Collection key", bindable: true),
        columns: Field.action_list("columns", label: "Columns"),
        zebra: Field.toggle("zebra", label: "Zebra rows"),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Extra small", "xs"}, {"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
