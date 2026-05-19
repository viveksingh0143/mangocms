defmodule MangoCMSWeb.Builder.Manifests.Range do
  @moduledoc "Builder manifest for the range slider component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "range",
      label: "Range",
      group: "Data input",
      icon: "hero-adjustments-horizontal",
      renderer: {InputComponents, :range},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "label" => "Volume",
        "field_name" => "volume",
        "min" => 0,
        "max" => 100,
        "step" => 1,
        "value" => 50,
        "disabled" => false,
        "tone" => "",
        "size" => "",
        "show_steps" => false,
        "show_value" => false,
        "help" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Standard range slider",
          default_props: %{"show_steps" => false},
          fields: [
            :label,
            :field_name,
            :min,
            :max,
            :step,
            :disabled,
            :tone,
            :size,
            :show_value,
            :help,
            :classes
          ]
        },
        %{
          id: "stepped",
          label: "Stepped",
          description: "Range slider with visible step ticks",
          default_props: %{"show_steps" => true, "step" => 25, "max" => 100},
          fields: [
            :label,
            :field_name,
            :min,
            :max,
            :step,
            :disabled,
            :tone,
            :size,
            :show_value,
            :help,
            :classes
          ]
        }
      ],
      examples: [
        %{variant: "default", props: %{"label" => "Volume", "tone" => "primary"}},
        %{
          variant: "stepped",
          props: %{"label" => "Brightness", "step" => 25, "show_steps" => true}
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        min: Field.number("min", label: "Min"),
        max: Field.number("max", label: "Max"),
        step: Field.number("step", label: "Step", min: 1),
        disabled: Field.toggle("disabled", label: "Disabled"),
        show_steps: Field.toggle("show_steps", label: "Show step ticks"),
        show_value: Field.toggle("show_value", label: "Show current value"),
        tone:
          Field.select("tone",
            label: "Tone",
            options: [
              {"Default", ""},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Success", "success"},
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
