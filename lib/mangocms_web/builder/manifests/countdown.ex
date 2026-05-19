defmodule MangoCMSWeb.Builder.Manifests.Countdown do
  @moduledoc "Builder manifest for the countdown timer component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "countdown",
      label: "Countdown",
      group: "Data display",
      icon: "hero-clock",
      renderer: {DisplayComponents, :countdown},
      default_variant: "full",
      accepted_children: [],
      default_props: %{
        "target_seconds" => 86_400,
        "show_days" => false,
        "label_days" => "days",
        "label_hours" => "hours",
        "label_minutes" => "min",
        "label_seconds" => "sec"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "countdown", owns: ["dd", "hh", "mm", "ss", "remaining"]},
      slots: [],
      variants: [
        %{
          id: "full",
          label: "Full",
          description: "Days, hours, minutes, seconds",
          default_props: %{"show_days" => true, "target_seconds" => 90_061},
          fields: [
            :target_seconds,
            :show_days,
            :label_days,
            :label_hours,
            :label_minutes,
            :label_seconds,
            :classes
          ]
        },
        %{
          id: "minimal",
          label: "Minimal",
          description: "Hours, minutes, seconds",
          default_props: %{"show_days" => false},
          fields: [:target_seconds, :label_hours, :label_minutes, :label_seconds, :classes]
        }
      ],
      examples: [
        %{variant: "full", props: %{"target_seconds" => 90_061, "show_days" => true}},
        %{variant: "minimal", props: %{"target_seconds" => 3_661}}
      ],
      fields: %{
        target_seconds:
          Field.number("target_seconds",
            label: "Target (seconds)",
            min: 1,
            max: 999_999,
            bindable: true
          ),
        show_days: Field.toggle("show_days", label: "Show days"),
        label_days: Field.text("label_days", label: "Days label"),
        label_hours: Field.text("label_hours", label: "Hours label"),
        label_minutes: Field.text("label_minutes", label: "Minutes label"),
        label_seconds: Field.text("label_seconds", label: "Seconds label"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
