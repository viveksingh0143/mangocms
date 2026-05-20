defmodule MangoCMSWeb.Builder.Manifests.Section do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "section",
      label: "Section",
      group: "Layout",
      icon: "hero-rectangle-stack",
      renderer: {LayoutComponents, :section},
      default_variant: "default",
      accepted_children: ["container", "row", "heading", "paragraph", "button"],
      default_props: %{
        "padding_y" => "lg",
        "padding_x" => "md",
        "bg" => "base",
        "bg_image" => "",
        "max_width" => "",
        "id" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Standard section",
          default_props: %{},
          fields: [:padding_y, :padding_x, :bg, :max_width, :id, :classes]
        },
        %{
          id: "hero",
          label: "Hero",
          description: "Large hero section",
          default_props: %{"padding_y" => "2xl", "bg" => "base-200"},
          fields: [:padding_y, :padding_x, :bg, :bg_image, :max_width, :id, :classes]
        }
      ],
      fields: %{
        padding_y:
          Field.select("padding_y",
            label: "Padding Y",
            options: [
              {"None", "none"},
              {"XS", "xs"},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"XL", "xl"},
              {"2XL", "2xl"}
            ]
          ),
        padding_x:
          Field.select("padding_x",
            label: "Padding X",
            options: [
              {"None", "none"},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"XL", "xl"}
            ]
          ),
        bg:
          Field.select("bg",
            label: "Background",
            options: [
              {"Base", "base"},
              {"Base 100", "base-100"},
              {"Base 200", "base-200"},
              {"Base 300", "base-300"},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Neutral", "neutral"},
              {"Transparent", "transparent"}
            ]
          ),
        bg_image: Field.media("bg_image", label: "Background image"),
        max_width:
          Field.select("max_width",
            label: "Max Width",
            options: [
              {"Full", ""},
              {"7XL", "7xl"},
              {"6XL", "6xl"},
              {"5XL", "5xl"},
              {"4XL", "4xl"}
            ]
          ),
        id: Field.text("id", label: "Section ID (anchor)"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
