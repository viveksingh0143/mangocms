defmodule MangoCMSWeb.Builder.Manifests.TextGradient do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "text_gradient",
      label: "Text Gradient",
      group: "Typography",
      icon: "hero-sparkles",
      renderer: {TypographyComponents, :text_gradient},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "text" => "Gradient Text",
        "from_color" => "#6366f1",
        "to_color" => "#ec4899",
        "direction" => "to_right",
        "size" => "base",
        "weight" => "bold"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Horizontal gradient text",
          default_props: %{},
          fields: [:text, :from_color, :to_color, :direction, :size, :weight, :classes]
        }
      ],
      fields: %{
        text: Field.text("text", label: "Text", bindable: true, required: true),
        from_color: Field.color("from_color", label: "From color"),
        to_color: Field.color("to_color", label: "To color"),
        direction:
          Field.select("direction",
            label: "Direction",
            options: [
              {"→ Right", "to_right"},
              {"↓ Down", "to_bottom"},
              {"↘ Diagonal", "diagonal"},
              {"↙ Diagonal reverse", "diagonal_reverse"}
            ]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"XL", "xl"},
              {"2XL", "2xl"}
            ]
          ),
        weight:
          Field.select("weight",
            label: "Weight",
            options: [
              {"Normal", "normal"},
              {"Semibold", "semibold"},
              {"Bold", "bold"},
              {"Extra Bold", "extrabold"},
              {"Black", "black"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
