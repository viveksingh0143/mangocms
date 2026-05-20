defmodule MangoCMSWeb.Builder.Manifests.Paragraph do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "paragraph",
      label: "Paragraph",
      group: "Typography",
      icon: "hero-bars-3-bottom-left",
      renderer: {TypographyComponents, :paragraph},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "body" => "Enter your paragraph text here. Click to edit and make it your own.",
        "size" => "base",
        "align" => "left",
        "color" => "default",
        "max_width" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Standard body text",
          default_props: %{},
          fields: [:body, :size, :align, :color, :max_width, :classes]
        },
        %{
          id: "lead",
          label: "Lead",
          description: "Larger intro paragraph",
          default_props: %{"size" => "lg"},
          fields: [:body, :size, :align, :color, :max_width, :classes]
        },
        %{
          id: "muted",
          label: "Muted",
          description: "Subdued secondary text",
          default_props: %{"color" => "muted", "size" => "sm"},
          fields: [:body, :size, :align, :color, :max_width, :classes]
        }
      ],
      fields: %{
        body: Field.textarea("body", label: "Text", bindable: true, required: true),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"XS", "xs"},
              {"SM", "sm"},
              {"Base", "base"},
              {"LG", "lg"},
              {"XL", "xl"}
            ]
          ),
        align:
          Field.select("align",
            label: "Align",
            options: [
              {"Left", "left"},
              {"Center", "center"},
              {"Right", "right"},
              {"Justify", "justify"}
            ]
          ),
        color:
          Field.select("color",
            label: "Color",
            options: [
              {"Default", "default"},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Muted", "muted"},
              {"Error", "error"}
            ]
          ),
        max_width:
          Field.select("max_width",
            label: "Max Width",
            options: [
              {"None", ""},
              {"XS", "xs"},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"XL", "xl"},
              {"2XL", "2xl"},
              {"3XL", "3xl"},
              {"Prose", "prose"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
