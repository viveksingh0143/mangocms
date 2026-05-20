defmodule MangoCMSWeb.Builder.Manifests.Grid do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "grid",
      label: "Grid",
      group: "Layout",
      icon: "hero-squares-2x2",
      renderer: {LayoutComponents, :grid},
      default_variant: "cols_3",
      accepted_children: ["column", "card", "feature_card", "image", "heading"],
      default_props: %{
        "columns" => "3",
        "gap" => "md",
        "align" => "start"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "cols_2",
          label: "2 Cols",
          description: "2-column CSS grid",
          default_props: %{"columns" => "2"},
          fields: [:columns, :gap, :align, :classes]
        },
        %{
          id: "cols_3",
          label: "3 Cols",
          description: "3-column CSS grid",
          default_props: %{"columns" => "3"},
          fields: [:columns, :gap, :align, :classes]
        },
        %{
          id: "cols_4",
          label: "4 Cols",
          description: "4-column CSS grid",
          default_props: %{"columns" => "4"},
          fields: [:columns, :gap, :align, :classes]
        }
      ],
      fields: %{
        columns:
          Field.text("columns", label: "Columns (number or CSS template)", bindable: false),
        gap:
          Field.select("gap",
            label: "Gap",
            options: [
              {"None", "none"},
              {"XS", "xs"},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"XL", "xl"}
            ]
          ),
        align:
          Field.select("align",
            label: "Align Items",
            options: [
              {"Start", "start"},
              {"Center", "center"},
              {"End", "end"},
              {"Stretch", "stretch"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
