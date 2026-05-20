defmodule MangoCMSWeb.Builder.Manifests.Spacer do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "spacer",
      label: "Spacer",
      group: "Layout",
      icon: "hero-arrows-up-down",
      renderer: {LayoutComponents, :spacer},
      default_variant: "md",
      accepted_children: [],
      default_props: %{"size" => "md"},
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "sm",
          label: "SM",
          description: "Small spacer",
          default_props: %{"size" => "sm"},
          fields: [:size, :classes]
        },
        %{
          id: "md",
          label: "MD",
          description: "Medium spacer",
          default_props: %{"size" => "md"},
          fields: [:size, :classes]
        },
        %{
          id: "lg",
          label: "LG",
          description: "Large spacer",
          default_props: %{"size" => "lg"},
          fields: [:size, :classes]
        },
        %{
          id: "xl",
          label: "XL",
          description: "Extra large spacer",
          default_props: %{"size" => "xl"},
          fields: [:size, :classes]
        }
      ],
      fields: %{
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"XS (0.5rem)", "xs"},
              {"SM (1rem)", "sm"},
              {"MD (2rem)", "md"},
              {"LG (3rem)", "lg"},
              {"XL (5rem)", "xl"},
              {"2XL (8rem)", "2xl"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
