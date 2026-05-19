defmodule MangoCMSWeb.Builder.Manifests.RadialProgress do
  @moduledoc "Builder manifest for radial progress indicators."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.FeedbackComponents

  @impl true
  def manifest do
    %{
      name: "radial_progress",
      label: "Radial Progress",
      group: "Feedback",
      icon: "hero-chart-pie",
      renderer: {FeedbackComponents, :radial_progress},
      default_variant: "circle",
      accepted_children: [],
      default_props: %{
        "value" => 70,
        "label" => "70%",
        "tone" => "primary",
        "size" => "md",
        "diameter" => "5rem",
        "thickness" => "0.45rem"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{id: "circle", label: "Circle", fields: fields()},
        %{
          id: "success",
          label: "Success",
          default_props: %{"tone" => "success", "value" => 90},
          fields: fields()
        },
        %{
          id: "compact",
          label: "Compact",
          default_props: %{"size" => "sm", "diameter" => "3.5rem"},
          fields: fields()
        }
      ],
      examples: [
        %{variant: "circle", props: %{"value" => 70, "label" => "70%"}},
        %{variant: "success", props: %{"value" => 90, "tone" => "success", "label" => "90%"}},
        %{variant: "compact", props: %{"value" => 45, "diameter" => "3.5rem", "label" => "45%"}}
      ],
      fields: %{
        value: Field.number("value", label: "Value", min: 0, max: 100),
        label: Field.text("label", label: "Label", bindable: true),
        tone: tone_field(),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        diameter: Field.text("diameter", label: "Diameter"),
        thickness: Field.text("thickness", label: "Thickness"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end

  defp fields, do: [:value, :label, :tone, :size, :diameter, :thickness, :classes]

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
