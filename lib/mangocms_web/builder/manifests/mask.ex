defmodule MangoCMSWeb.Builder.Manifests.Mask do
  @moduledoc "Builder manifest for the mask layout component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "mask",
      label: "Mask",
      group: "Layout",
      icon: "hero-sparkles",
      renderer: {LayoutComponents, :mask},
      default_variant: "circle",
      accepted_children: ["image", "avatar", "card"],
      default_props: %{
        "shape" => "circle",
        "size" => "md",
        "image_src" => "/images/no-image-placeholder.webp",
        "image_alt" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "content", label: "Content", accepts: ["image", "avatar", "card"], max_children: 1}
      ],
      variants: [
        %{
          id: "circle",
          label: "Circle",
          description: "Circular media mask",
          default_props: %{"shape" => "circle"},
          fields: [:shape, :size, :image_src, :image_alt, :classes, :slots],
          slots: ["content"]
        },
        %{
          id: "squircle",
          label: "Squircle",
          description: "Rounded organic shape",
          default_props: %{"shape" => "squircle"},
          fields: [:shape, :size, :image_src, :image_alt, :classes, :slots],
          slots: ["content"]
        },
        %{
          id: "hexagon",
          label: "Hexagon",
          description: "Angular media mask",
          default_props: %{"shape" => "hexagon"},
          fields: [:shape, :size, :image_src, :image_alt, :classes, :slots],
          slots: ["content"]
        }
      ],
      examples: [
        %{variant: "circle", props: %{}},
        %{variant: "squircle", props: %{}},
        %{variant: "hexagon", props: %{}}
      ],
      fields: %{
        shape:
          Field.select("shape",
            label: "Shape",
            options: [
              {"Circle", "circle"},
              {"Squircle", "squircle"},
              {"Heart", "heart"},
              {"Hexagon", "hexagon"},
              {"Triangle", "triangle"}
            ]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}, {"Extra large", "xl"}]
          ),
        image_src: Field.media("image_src", label: "Image", bindable: true),
        image_alt: Field.text("image_alt", label: "Image alt text", bindable: true),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
