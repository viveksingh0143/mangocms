defmodule MangoCMSWeb.Builder.Manifests.LabelText do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "label_text",
      label: "Label / Eyebrow",
      group: "Typography",
      icon: "hero-tag",
      renderer: {TypographyComponents, :label_text},
      default_variant: "primary",
      accepted_children: [],
      default_props: %{
        "text" => "Section Label",
        "size" => "default",
        "color" => "primary"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "primary",
          label: "Primary",
          description: "Primary colored eyebrow",
          default_props: %{"color" => "primary"},
          fields: [:text, :size, :color, :classes]
        },
        %{
          id: "muted",
          label: "Muted",
          description: "Subdued label",
          default_props: %{"color" => "muted"},
          fields: [:text, :size, :color, :classes]
        }
      ],
      fields: %{
        text: Field.text("text", label: "Text", bindable: true, required: true),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"XS", "xs"},
              {"SM", "sm"},
              {"Default", "default"},
              {"LG", "lg"}
            ]
          ),
        color:
          Field.select("color",
            label: "Color",
            options: [
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Muted", "muted"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
