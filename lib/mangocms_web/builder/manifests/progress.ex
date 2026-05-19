defmodule MangoCMSWeb.Builder.Manifests.Progress do
  @moduledoc "Builder manifest for progress bars."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.FeedbackComponents

  @impl true
  def manifest do
    %{
      name: "progress",
      label: "Progress",
      group: "Feedback",
      icon: "hero-chart-bar",
      renderer: {FeedbackComponents, :progress},
      default_variant: "bar",
      accepted_children: [],
      default_props: %{
        "label" => "Progress",
        "value" => 65,
        "max" => 100,
        "tone" => "primary",
        "size" => "md"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{id: "bar", label: "Bar", fields: fields()},
        %{
          id: "success",
          label: "Success",
          default_props: %{"tone" => "success"},
          fields: fields()
        },
        %{
          id: "warning",
          label: "Warning",
          default_props: %{"tone" => "warning"},
          fields: fields()
        }
      ],
      examples: [
        %{variant: "bar", props: %{"value" => 65}},
        %{variant: "success", props: %{"value" => 90, "tone" => "success"}},
        %{variant: "warning", props: %{"value" => 45, "tone" => "warning"}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        value: Field.number("value", label: "Value", min: 0, max: 100),
        max: Field.number("max", label: "Max", min: 1),
        tone: tone_field(),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end

  defp fields, do: [:label, :value, :max, :tone, :size, :classes]

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
