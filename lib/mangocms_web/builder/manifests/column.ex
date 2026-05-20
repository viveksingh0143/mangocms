defmodule MangoCMSWeb.Builder.Manifests.Column do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "column",
      label: "Column",
      group: "Layout",
      icon: "hero-rectangle-group",
      renderer: {LayoutComponents, :column},
      default_variant: "default",
      accepted_children: ["heading", "paragraph", "image", "button", "rich_text"],
      default_props: %{
        "span" => "auto",
        "padding" => "none",
        "align" => "start"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Flexible column",
          default_props: %{},
          fields: [:span, :padding, :align, :classes]
        }
      ],
      fields: %{
        span:
          Field.select("span",
            label: "Column Span",
            options: [
              {"Auto", "auto"},
              {"1", "1"},
              {"2", "2"},
              {"3", "3"},
              {"4", "4"},
              {"6", "6"},
              {"Full", "full"}
            ]
          ),
        padding:
          Field.select("padding",
            label: "Padding",
            options: [
              {"None", "none"},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"}
            ]
          ),
        align:
          Field.select("align",
            label: "Align Items",
            options: [
              {"Start", "start"},
              {"Center", "center"},
              {"End", "end"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
