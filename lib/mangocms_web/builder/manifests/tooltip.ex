defmodule MangoCMSWeb.Builder.Manifests.Tooltip do
  @moduledoc "Builder manifest for tooltips."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.FeedbackComponents

  @impl true
  def manifest do
    %{
      name: "tooltip",
      label: "Tooltip",
      group: "Feedback",
      icon: "hero-chat-bubble-bottom-center-text",
      renderer: {FeedbackComponents, :tooltip},
      default_variant: "top",
      accepted_children: ["button", "anchor", "icon", "badge"],
      default_props: %{
        "label" => "Hover me",
        "text" => "Helpful detail",
        "position" => "top",
        "tone" => "neutral",
        "trigger_style" => "btn-ghost",
        "size" => "md"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "tooltip", owns: ["focused"]},
      slots: [
        %{
          id: "trigger",
          label: "Trigger",
          accepts: ["button", "anchor", "icon", "badge"],
          max_children: 1
        }
      ],
      variants: [
        %{
          id: "top",
          label: "Top",
          default_props: %{"position" => "top"},
          fields: fields(),
          slots: ["trigger"]
        },
        %{
          id: "bottom",
          label: "Bottom",
          default_props: %{"position" => "bottom"},
          fields: fields(),
          slots: ["trigger"]
        },
        %{
          id: "accent",
          label: "Accent",
          default_props: %{"tone" => "primary"},
          fields: fields(),
          slots: ["trigger"]
        }
      ],
      examples: [
        %{variant: "top", props: %{"text" => "Top tooltip"}},
        %{variant: "bottom", props: %{"text" => "Bottom tooltip", "position" => "bottom"}},
        %{variant: "accent", props: %{"text" => "Primary tooltip", "tone" => "primary"}}
      ],
      fields: %{
        label: Field.text("label", label: "Trigger label", bindable: true),
        text: Field.text("text", label: "Tooltip text", bindable: true, required: true),
        position:
          Field.select("position",
            label: "Position",
            options: [{"Top", "top"}, {"Bottom", "bottom"}, {"Left", "left"}, {"Right", "right"}]
          ),
        tone: tone_field(),
        trigger_style:
          Field.select("trigger_style",
            label: "Trigger style",
            options: [
              {"Ghost", "btn-ghost"},
              {"Primary", "btn-primary"},
              {"Secondary", "btn-secondary"}
            ]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end

  defp fields, do: [:label, :text, :position, :tone, :trigger_style, :size, :classes, :slots]

  defp tone_field,
    do:
      Field.select("tone",
        label: "Tone",
        options: [
          {"Neutral", "neutral"},
          {"Primary", "primary"},
          {"Info", "info"},
          {"Success", "success"},
          {"Warning", "warning"},
          {"Error", "error"}
        ]
      )
end
