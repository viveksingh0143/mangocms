defmodule MangoCMSWeb.Builder.Manifests.Filter do
  @moduledoc "Builder manifest for the daisyUI filter bar component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "filter",
      label: "Filter",
      group: "Data input",
      icon: "hero-funnel",
      renderer: {InputComponents, :filter},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "label" => "",
        "field_name" => "filter",
        "reset_label" => "All",
        "default_value" => "",
        "tone" => "",
        "size" => "",
        "options" => [
          %{"label" => "Anime", "value" => "anime"},
          %{"label" => "Movies", "value" => "movies"},
          %{"label" => "TV Shows", "value" => "tv"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{
        component: "filter",
        owns: ["active"]
      },
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Neutral filter pills",
          default_props: %{"tone" => ""},
          fields: [:label, :field_name, :reset_label, :tone, :size, :classes]
        },
        %{
          id: "primary",
          label: "Primary",
          description: "Primary-coloured filter pills",
          default_props: %{"tone" => "primary"},
          fields: [:label, :field_name, :reset_label, :tone, :size, :classes]
        }
      ],
      examples: [
        %{
          variant: "default",
          props: %{"reset_label" => "All", "tone" => ""}
        },
        %{
          variant: "primary",
          props: %{"reset_label" => "All", "tone" => "primary"}
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        reset_label: Field.text("reset_label", label: "Reset button label"),
        tone:
          Field.select("tone",
            label: "Tone",
            options: [
              {"Default", ""},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"}
            ]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"Default", ""},
              {"Extra small", "xs"},
              {"Small", "sm"},
              {"Large", "lg"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
