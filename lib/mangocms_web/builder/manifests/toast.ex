defmodule MangoCMSWeb.Builder.Manifests.Toast do
  @moduledoc "Builder manifest for toast notifications."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.FeedbackComponents

  @impl true
  def manifest do
    %{
      name: "toast",
      label: "Toast",
      group: "Feedback",
      icon: "hero-bell-alert",
      renderer: {FeedbackComponents, :toast},
      default_variant: "info",
      accepted_children: ["paragraph", "button", "anchor"],
      default_props: %{
        "message" => "Toast message",
        "tone" => "info",
        "position" => "bottom_end",
        "auto_close" => false,
        "duration_ms" => 3000,
        "size" => "md"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "toast", owns: ["open"], timers: true},
      slots: [
        %{
          id: "content",
          label: "Content",
          accepts: ["paragraph", "button", "anchor"],
          max_children: 3
        }
      ],
      variants: [
        %{
          id: "info",
          label: "Info",
          default_props: %{"tone" => "info"},
          fields: fields(),
          slots: ["content"]
        },
        %{
          id: "success",
          label: "Success",
          default_props: %{"tone" => "success"},
          fields: fields(),
          slots: ["content"]
        },
        %{
          id: "error",
          label: "Error",
          default_props: %{"tone" => "error"},
          fields: fields(),
          slots: ["content"]
        }
      ],
      examples: [
        %{variant: "info", props: %{"message" => "Helpful update"}},
        %{variant: "success", props: %{"message" => "Saved successfully", "tone" => "success"}},
        %{variant: "error", props: %{"message" => "Action failed", "tone" => "error"}}
      ],
      fields: %{
        message: Field.text("message", label: "Message", bindable: true),
        tone: tone_field(),
        position:
          Field.select("position",
            label: "Position",
            options: [
              {"Bottom end", "bottom_end"},
              {"Bottom start", "bottom_start"},
              {"Top end", "top_end"},
              {"Top start", "top_start"}
            ]
          ),
        auto_close: Field.toggle("auto_close", label: "Auto close"),
        duration_ms: Field.number("duration_ms", label: "Duration ms", min: 500, max: 10000),
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

  defp fields,
    do: [:message, :tone, :position, :auto_close, :duration_ms, :size, :classes, :slots]

  defp tone_field,
    do:
      Field.select("tone",
        label: "Tone",
        options: [
          {"Info", "info"},
          {"Success", "success"},
          {"Warning", "warning"},
          {"Error", "error"}
        ]
      )
end
