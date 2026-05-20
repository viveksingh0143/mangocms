defmodule MangoCMSWeb.Builder.Manifests.UnorderedList do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "unordered_list",
      label: "Unordered List",
      group: "Typography",
      icon: "hero-list-bullet",
      renderer: {TypographyComponents, :unordered_list},
      default_variant: "disc",
      accepted_children: [],
      default_props: %{
        "items" => [
          %{"label" => "First item"},
          %{"label" => "Second item"},
          %{"label" => "Third item"}
        ],
        "style" => "disc"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "disc",
          label: "Disc",
          description: "Filled bullet points",
          default_props: %{"style" => "disc"},
          fields: [:items, :style, :classes]
        },
        %{
          id: "circle",
          label: "Circle",
          description: "Open circles",
          default_props: %{"style" => "circle"},
          fields: [:items, :style, :classes]
        },
        %{
          id: "none",
          label: "None",
          description: "No bullets",
          default_props: %{"style" => "none"},
          fields: [:items, :style, :classes]
        }
      ],
      fields: %{
        items: Field.action_list("items", label: "Items"),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Disc", "disc"},
              {"Circle", "circle"},
              {"Square", "square"},
              {"None", "none"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
