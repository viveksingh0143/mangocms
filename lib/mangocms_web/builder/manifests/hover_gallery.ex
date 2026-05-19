defmodule MangoCMSWeb.Builder.Manifests.HoverGallery do
  @moduledoc "Builder manifest for the hover gallery component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "hover_gallery",
      label: "Hover gallery",
      group: "Data display",
      icon: "hero-photo",
      renderer: {DisplayComponents, :hover_gallery},
      default_variant: "grid_3",
      accepted_children: ["image"],
      default_props: %{
        "columns" => 3,
        "gap" => "md",
        "effect" => "zoom",
        "collection" => "",
        "image_template" => "{{item.image}}",
        "caption_template" => "{{item.title}}"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "items", label: "Items", accepts: ["image", "card"]}
      ],
      variants: [
        %{
          id: "grid_3",
          label: "3-column grid",
          description: "Three-column image grid",
          default_props: %{"columns" => 3},
          fields: [
            :columns,
            :gap,
            :effect,
            :collection,
            :image_template,
            :caption_template,
            :classes,
            :slots
          ],
          slots: ["items"]
        },
        %{
          id: "grid_4",
          label: "4-column grid",
          description: "Four-column image grid",
          default_props: %{"columns" => 4},
          fields: [
            :columns,
            :gap,
            :effect,
            :collection,
            :image_template,
            :caption_template,
            :classes,
            :slots
          ],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "grid_3", props: %{"columns" => 3, "effect" => "zoom"}},
        %{variant: "grid_4", props: %{"columns" => 4, "effect" => "grayscale"}}
      ],
      fields: %{
        columns:
          Field.select("columns",
            label: "Columns",
            options: [
              {"2", "2"},
              {"3", "3"},
              {"4", "4"},
              {"5", "5"}
            ]
          ),
        gap:
          Field.select("gap",
            label: "Gap",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        effect:
          Field.select("effect",
            label: "Hover effect",
            options: [
              {"Zoom in", "zoom"},
              {"Zoom out", "zoom_out"},
              {"Brightness", "brightness"},
              {"Grayscale to colour", "grayscale"}
            ]
          ),
        collection: Field.text("collection", label: "Collection key", bindable: true),
        image_template: Field.text("image_template", label: "Image template", bindable: true),
        caption_template:
          Field.text("caption_template", label: "Caption template", bindable: true),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
