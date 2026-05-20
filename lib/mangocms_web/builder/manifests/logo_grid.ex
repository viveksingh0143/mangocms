defmodule MangoCMSWeb.Builder.Manifests.LogoGrid do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "logo_grid",
      label: "Logo Grid",
      group: "Content",
      icon: "hero-building-office",
      renderer: {ContentComponents, :logo_grid},
      default_variant: "grayscale",
      accepted_children: [],
      default_props: %{
        "label" => "Trusted by",
        "logos" => [
          %{"src" => "/images/no-image-placeholder.webp", "alt" => "Company 1"},
          %{"src" => "/images/no-image-placeholder.webp", "alt" => "Company 2"},
          %{"src" => "/images/no-image-placeholder.webp", "alt" => "Company 3"},
          %{"src" => "/images/no-image-placeholder.webp", "alt" => "Company 4"}
        ],
        "grayscale" => true,
        "gap" => "md"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "grayscale",
          label: "Grayscale",
          description: "Muted grayscale logos",
          default_props: %{"grayscale" => true},
          fields: [:label, :logos, :grayscale, :gap, :classes]
        },
        %{
          id: "color",
          label: "Color",
          description: "Full-color logos",
          default_props: %{"grayscale" => false},
          fields: [:label, :logos, :grayscale, :gap, :classes]
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label text", bindable: true),
        logos: Field.action_list("logos", label: "Logos"),
        grayscale: Field.toggle("grayscale", label: "Grayscale"),
        gap:
          Field.select("gap",
            label: "Gap",
            options: [
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
