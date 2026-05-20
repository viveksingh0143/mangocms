defmodule MangoCMSWeb.Builder.Manifests.OrderedList do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "ordered_list",
      label: "Ordered List",
      group: "Typography",
      icon: "hero-list-bullet",
      renderer: {TypographyComponents, :ordered_list},
      default_variant: "decimal",
      accepted_children: [],
      default_props: %{
        "items" => [
          %{"label" => "First item"},
          %{"label" => "Second item"},
          %{"label" => "Third item"}
        ],
        "style" => "decimal"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "decimal",
          label: "Numbers",
          description: "1, 2, 3...",
          default_props: %{"style" => "decimal"},
          fields: [:items, :style, :classes]
        },
        %{
          id: "alpha",
          label: "Letters",
          description: "a, b, c...",
          default_props: %{"style" => "alpha"},
          fields: [:items, :style, :classes]
        },
        %{
          id: "roman",
          label: "Roman",
          description: "i, ii, iii...",
          default_props: %{"style" => "roman"},
          fields: [:items, :style, :classes]
        }
      ],
      fields: %{
        items: Field.action_list("items", label: "Items"),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Decimal", "decimal"},
              {"Alpha", "alpha"},
              {"Roman", "roman"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
