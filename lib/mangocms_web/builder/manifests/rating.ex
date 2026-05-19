defmodule MangoCMSWeb.Builder.Manifests.Rating do
  @moduledoc "Builder manifest for the rating input component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "rating",
      label: "Rating",
      group: "Data input",
      icon: "hero-star",
      renderer: {InputComponents, :rating},
      default_variant: "stars",
      accepted_children: [],
      default_props: %{
        "label" => "Rating",
        "field_name" => "rating",
        "count" => 5,
        "value" => 0,
        "shape" => "star",
        "color" => "",
        "size" => "",
        "help" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "stars",
          label: "Stars",
          description: "Star rating input",
          default_props: %{"shape" => "star"},
          fields: [:label, :field_name, :count, :color, :size, :help, :classes]
        },
        %{
          id: "hearts",
          label: "Hearts",
          description: "Heart rating input",
          default_props: %{"shape" => "heart"},
          fields: [:label, :field_name, :count, :color, :size, :help, :classes]
        }
      ],
      examples: [
        %{
          variant: "stars",
          props: %{"label" => "Product rating", "count" => 5, "shape" => "star"}
        },
        %{
          variant: "hearts",
          props: %{"label" => "How much did you enjoy it?", "count" => 5, "shape" => "heart"}
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        count: Field.number("count", label: "Star count", min: 1, max: 10),
        shape:
          Field.select("shape",
            label: "Shape",
            options: [
              {"Star", "star"},
              {"Heart", "heart"},
              {"Diamond", "diamond"}
            ]
          ),
        color:
          Field.select("color",
            label: "Color",
            options: [
              {"Orange (default)", ""},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Warning", "warning"},
              {"Error", "error"}
            ]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"Default", ""},
              {"Extra small", "xs"},
              {"Small", "sm"},
              {"Large", "lg"},
              {"Extra large", "xl"}
            ]
          ),
        help: Field.text("help", label: "Help text", bindable: true),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
