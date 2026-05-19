defmodule MangoCMSWeb.Builder.Manifests.Loading do
  @moduledoc "Builder manifest for loading indicators."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.FeedbackComponents

  @impl true
  def manifest do
    %{
      name: "loading",
      label: "Loading",
      group: "Feedback",
      icon: "hero-arrow-path",
      renderer: {FeedbackComponents, :loading},
      default_variant: "spinner",
      accepted_children: [],
      default_props: %{
        "style" => "spinner",
        "size" => "md",
        "tone" => "primary",
        "label" => "Loading"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "spinner",
          label: "Spinner",
          default_props: %{"style" => "spinner"},
          fields: fields()
        },
        %{id: "dots", label: "Dots", default_props: %{"style" => "dots"}, fields: fields()},
        %{id: "ring", label: "Ring", default_props: %{"style" => "ring"}, fields: fields()},
        %{id: "bars", label: "Bars", default_props: %{"style" => "bars"}, fields: fields()}
      ],
      examples: [
        %{variant: "spinner", props: %{"style" => "spinner"}},
        %{variant: "dots", props: %{"style" => "dots"}},
        %{variant: "ring", props: %{"style" => "ring"}},
        %{variant: "bars", props: %{"style" => "bars"}}
      ],
      fields: %{
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Spinner", "spinner"},
              {"Dots", "dots"},
              {"Ring", "ring"},
              {"Ball", "ball"},
              {"Bars", "bars"}
            ]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"XS", "xs"},
              {"Small", "sm"},
              {"Medium", "md"},
              {"Large", "lg"},
              {"XL", "xl"}
            ]
          ),
        tone: tone_field(),
        label: Field.text("label", label: "Accessible label"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end

  defp fields, do: [:style, :size, :tone, :label, :classes]

  defp tone_field,
    do:
      Field.select("tone",
        label: "Tone",
        options: [
          {"Primary", "primary"},
          {"Secondary", "secondary"},
          {"Info", "info"},
          {"Success", "success"},
          {"Warning", "warning"},
          {"Error", "error"}
        ]
      )
end
