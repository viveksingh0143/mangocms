defmodule MangoCMSWeb.Builder.Manifests.Heading do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "heading",
      label: "Heading",
      group: "Typography",
      icon: "hero-h1",
      renderer: {TypographyComponents, :heading},
      default_variant: "h2",
      accepted_children: [],
      default_props: %{
        "text" => "Your Heading Here",
        "level" => "2",
        "size" => "lg",
        "weight" => "bold",
        "align" => "left",
        "color" => "default"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "h1",
          label: "H1",
          description: "Page title",
          default_props: %{"level" => "1", "size" => "2xl"},
          fields: [:text, :size, :weight, :align, :color, :classes]
        },
        %{
          id: "h2",
          label: "H2",
          description: "Section heading",
          default_props: %{"level" => "2", "size" => "xl"},
          fields: [:text, :size, :weight, :align, :color, :classes]
        },
        %{
          id: "h3",
          label: "H3",
          description: "Sub-section heading",
          default_props: %{"level" => "3", "size" => "lg"},
          fields: [:text, :size, :weight, :align, :color, :classes]
        },
        %{
          id: "h4",
          label: "H4",
          description: "Minor heading",
          default_props: %{"level" => "4", "size" => "md"},
          fields: [:text, :size, :weight, :align, :color, :classes]
        }
      ],
      fields: %{
        text: Field.text("text", label: "Text", bindable: true, required: true),
        level:
          Field.select("level",
            label: "HTML Level",
            options: [
              {"H1", "1"},
              {"H2", "2"},
              {"H3", "3"},
              {"H4", "4"},
              {"H5", "5"},
              {"H6", "6"}
            ]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"XS", "xs"},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"XL", "xl"},
              {"2XL", "2xl"},
              {"3XL", "3xl"}
            ]
          ),
        weight:
          Field.select("weight",
            label: "Weight",
            options: [
              {"Thin", "thin"},
              {"Light", "light"},
              {"Normal", "normal"},
              {"Medium", "medium"},
              {"Semibold", "semibold"},
              {"Bold", "bold"},
              {"Extra Bold", "extrabold"},
              {"Black", "black"}
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
              {"Muted", "muted"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
