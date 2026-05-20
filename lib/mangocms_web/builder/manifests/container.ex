defmodule MangoCMSWeb.Builder.Manifests.Container do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "container",
      label: "Container",
      group: "Layout",
      icon: "hero-square-3-stack-3d",
      renderer: {LayoutComponents, :container},
      default_variant: "default",
      accepted_children: ["row", "heading", "paragraph", "image", "button"],
      default_props: %{
        "max_width" => "7xl",
        "padding_x" => "md",
        "padding_y" => "none",
        "bg" => "",
        "rounded" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Centered max-width container",
          default_props: %{},
          fields: [:max_width, :padding_x, :padding_y, :bg, :rounded, :classes]
        },
        %{
          id: "card",
          label: "Card",
          description: "Rounded card container",
          default_props: %{
            "bg" => "base-100",
            "rounded" => "xl",
            "padding_x" => "lg",
            "padding_y" => "lg"
          },
          fields: [:max_width, :padding_x, :padding_y, :bg, :rounded, :classes]
        }
      ],
      fields: %{
        max_width:
          Field.select("max_width",
            label: "Max Width",
            options: [
              {"Full", ""},
              {"7XL", "7xl"},
              {"6XL", "6xl"},
              {"5XL", "5xl"},
              {"4XL", "4xl"},
              {"3XL", "3xl"},
              {"2XL", "2xl"},
              {"XL", "xl"},
              {"LG", "lg"}
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
        padding_y:
          Field.select("padding_y",
            label: "Padding Y",
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
              {"None", ""},
              {"Base 100", "base-100"},
              {"Base 200", "base-200"},
              {"Primary", "primary"}
            ]
          ),
        rounded:
          Field.select("rounded",
            label: "Rounded",
            options: [
              {"None", ""},
              {"LG", "lg"},
              {"XL", "xl"},
              {"2XL", "2xl"},
              {"3XL", "3xl"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
