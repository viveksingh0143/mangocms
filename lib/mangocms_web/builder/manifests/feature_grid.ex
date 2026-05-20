defmodule MangoCMSWeb.Builder.Manifests.FeatureGrid do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "feature_grid",
      label: "Feature Grid",
      group: "Content",
      icon: "hero-squares-plus",
      renderer: {ContentComponents, :feature_grid},
      default_variant: "grid_3",
      accepted_children: [],
      default_props: %{
        "items" => [
          %{"icon" => "hero-bolt", "title" => "Fast", "body" => "Lightning fast performance."},
          %{
            "icon" => "hero-shield-check",
            "title" => "Secure",
            "body" => "Enterprise-grade security."
          },
          %{"icon" => "hero-chart-bar", "title" => "Scalable", "body" => "Grows with your team."}
        ],
        "columns" => "3",
        "gap" => "md",
        "card_variant" => "bordered",
        "icon_color" => "primary"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "grid_2",
          label: "2 Cols",
          description: "Two-column feature grid",
          default_props: %{"columns" => "2"},
          fields: [:items, :columns, :gap, :card_variant, :icon_color, :classes]
        },
        %{
          id: "grid_3",
          label: "3 Cols",
          description: "Three-column feature grid",
          default_props: %{"columns" => "3"},
          fields: [:items, :columns, :gap, :card_variant, :icon_color, :classes]
        },
        %{
          id: "grid_4",
          label: "4 Cols",
          description: "Four-column feature grid",
          default_props: %{"columns" => "4"},
          fields: [:items, :columns, :gap, :card_variant, :icon_color, :classes]
        }
      ],
      fields: %{
        items: Field.action_list("items", label: "Features"),
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
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"}
            ]
          ),
        card_variant:
          Field.select("card_variant",
            label: "Card style",
            options: [
              {"Bordered", "bordered"},
              {"Filled", "filled"},
              {"Ghost", "ghost"}
            ]
          ),
        icon_color:
          Field.select("icon_color",
            label: "Icon color",
            options: [
              {"Default", "default"},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
