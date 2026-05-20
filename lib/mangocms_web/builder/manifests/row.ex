defmodule MangoCMSWeb.Builder.Manifests.Row do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "row",
      label: "Row",
      group: "Layout",
      icon: "hero-bars-2",
      renderer: {LayoutComponents, :row},
      default_variant: "two_col",
      accepted_children: ["column", "heading", "paragraph", "image", "button"],
      default_props: %{
        "columns" => "2",
        "gap" => "md",
        "align" => "start",
        "justify" => "start"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "two_col",
          label: "2 Cols",
          description: "Two equal columns",
          default_props: %{"columns" => "2"},
          fields: [:columns, :gap, :align, :justify, :classes]
        },
        %{
          id: "three_col",
          label: "3 Cols",
          description: "Three equal columns",
          default_props: %{"columns" => "3"},
          fields: [:columns, :gap, :align, :justify, :classes]
        },
        %{
          id: "four_col",
          label: "4 Cols",
          description: "Four equal columns",
          default_props: %{"columns" => "4"},
          fields: [:columns, :gap, :align, :justify, :classes]
        },
        %{
          id: "sidebar_left",
          label: "Sidebar L",
          description: "1/3 sidebar left",
          default_props: %{"columns" => "sidebar_left"},
          fields: [:columns, :gap, :align, :justify, :classes]
        },
        %{
          id: "sidebar_right",
          label: "Sidebar R",
          description: "1/3 sidebar right",
          default_props: %{"columns" => "sidebar_right"},
          fields: [:columns, :gap, :align, :justify, :classes]
        }
      ],
      fields: %{
        columns:
          Field.select("columns",
            label: "Columns",
            options: [
              {"1", "1"},
              {"2", "2"},
              {"3", "3"},
              {"4", "4"},
              {"6", "6"},
              {"Sidebar Left (1/3 + 2/3)", "sidebar_left"},
              {"Sidebar Right (2/3 + 1/3)", "sidebar_right"}
            ]
          ),
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
        justify:
          Field.select("justify",
            label: "Justify",
            options: [
              {"Start", "start"},
              {"Center", "center"},
              {"End", "end"},
              {"Between", "between"},
              {"Around", "around"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
