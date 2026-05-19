defmodule MangoCMSWeb.Builder.Manifests.Divider do
  @moduledoc "Builder manifest for the divider layout component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "divider",
      label: "Divider",
      group: "Layout",
      icon: "hero-minus",
      renderer: {LayoutComponents, :divider},
      default_variant: "plain",
      accepted_children: [],
      default_props: %{
        "label" => "",
        "direction" => "vertical",
        "tone" => "base",
        "spacing" => "normal"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "plain",
          label: "Plain",
          description: "Simple separating rule",
          fields: [:label, :direction, :tone, :spacing, :classes]
        },
        %{
          id: "labeled",
          label: "Labeled",
          description: "Divider with centered text",
          default_props: %{"label" => "Section"},
          fields: [:label, :direction, :tone, :spacing, :classes]
        },
        %{
          id: "horizontal",
          label: "Horizontal split",
          description: "Vertical line between columns",
          default_props: %{"direction" => "horizontal"},
          fields: [:label, :direction, :tone, :spacing, :classes]
        }
      ],
      examples: [
        %{variant: "plain", props: %{}},
        %{variant: "labeled", props: %{"label" => "Features"}},
        %{variant: "horizontal", props: %{"label" => "or"}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        direction:
          Field.select("direction",
            label: "Direction",
            options: [{"Vertical", "vertical"}, {"Horizontal", "horizontal"}]
          ),
        tone:
          Field.select("tone",
            label: "Tone",
            options: [
              {"Base", "base"},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"}
            ]
          ),
        spacing:
          Field.select("spacing",
            label: "Spacing",
            options: [{"Compact", "compact"}, {"Normal", "normal"}, {"Relaxed", "relaxed"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
