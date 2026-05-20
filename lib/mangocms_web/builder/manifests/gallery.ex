defmodule MangoCMSWeb.Builder.Manifests.Gallery do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MediaComponents

  @impl true
  def manifest do
    %{
      name: "gallery",
      label: "Gallery",
      group: "Media",
      icon: "hero-squares-2x2",
      renderer: {MediaComponents, :gallery},
      default_variant: "grid_3",
      accepted_children: [],
      default_props: %{
        "images" => [
          %{"src" => "/images/no-image-placeholder.webp", "alt" => "Gallery image 1"},
          %{"src" => "/images/no-image-placeholder.webp", "alt" => "Gallery image 2"},
          %{"src" => "/images/no-image-placeholder.webp", "alt" => "Gallery image 3"}
        ],
        "columns" => "3",
        "gap" => "md",
        "rounded" => "sm"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "gallery", owns: ["open", "active"]},
      slots: [],
      variants: [
        %{
          id: "grid_2",
          label: "2 Cols",
          description: "Two column grid",
          default_props: %{"columns" => "2"},
          fields: [:images, :columns, :gap, :rounded, :classes]
        },
        %{
          id: "grid_3",
          label: "3 Cols",
          description: "Three column grid",
          default_props: %{"columns" => "3"},
          fields: [:images, :columns, :gap, :rounded, :classes]
        },
        %{
          id: "grid_4",
          label: "4 Cols",
          description: "Four column grid",
          default_props: %{"columns" => "4"},
          fields: [:images, :columns, :gap, :rounded, :classes]
        }
      ],
      fields: %{
        images: Field.action_list("images", label: "Images"),
        columns:
          Field.select("columns",
            label: "Columns",
            options: [
              {"2", "2"},
              {"3", "3"},
              {"4", "4"}
            ]
          ),
        gap:
          Field.select("gap",
            label: "Gap",
            options: [
              {"Tight", "sm"},
              {"Default", "md"},
              {"Loose", "lg"},
              {"XL", "xl"}
            ]
          ),
        rounded:
          Field.select("rounded",
            label: "Rounded",
            options: [
              {"None", ""},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
