defmodule MangoCMSWeb.Builder.Manifests.TestimonialGrid do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "testimonial_grid",
      label: "Testimonial Grid",
      group: "Content",
      icon: "hero-chat-bubble-bottom-center-text",
      renderer: {ContentComponents, :testimonial_grid},
      default_variant: "grid_2",
      accepted_children: [],
      default_props: %{
        "items" => [
          %{"quote" => "Incredible product!", "name" => "Alice B.", "role" => "CEO"},
          %{"quote" => "Changed everything.", "name" => "Bob C.", "role" => "CTO"},
          %{"quote" => "Highly recommend!", "name" => "Carol D.", "role" => "Designer"}
        ],
        "columns" => "3"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "grid_2",
          label: "2 Cols",
          description: "Two-column testimonials",
          default_props: %{"columns" => "2"},
          fields: [:items, :columns, :classes]
        },
        %{
          id: "grid_3",
          label: "3 Cols",
          description: "Three-column testimonials",
          default_props: %{"columns" => "3"},
          fields: [:items, :columns, :classes]
        }
      ],
      fields: %{
        items: Field.action_list("items", label: "Testimonials"),
        columns:
          Field.select("columns",
            label: "Columns",
            options: [
              {"2", "2"},
              {"3", "3"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
