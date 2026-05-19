defmodule MangoCMSWeb.Builder.Manifests.Radio do
  @moduledoc "Builder manifest for the radio button group component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "radio",
      label: "Radio",
      group: "Data input",
      icon: "hero-radio",
      renderer: {InputComponents, :radio},
      default_variant: "vertical",
      accepted_children: [],
      default_props: %{
        "label" => "Choose one",
        "field_name" => "choice",
        "required" => false,
        "disabled" => false,
        "direction" => "vertical",
        "tone" => "",
        "size" => "",
        "error" => false,
        "error_message" => "",
        "help" => "",
        "options" => [
          %{"label" => "Option 1", "value" => "1"},
          %{"label" => "Option 2", "value" => "2"},
          %{"label" => "Option 3", "value" => "3"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "vertical",
          label: "Vertical",
          description: "Stacked radio options",
          default_props: %{"direction" => "vertical"},
          fields: [
            :label,
            :field_name,
            :required,
            :disabled,
            :tone,
            :size,
            :help,
            :classes
          ]
        },
        %{
          id: "horizontal",
          label: "Horizontal",
          description: "Inline radio options",
          default_props: %{"direction" => "horizontal"},
          fields: [
            :label,
            :field_name,
            :required,
            :disabled,
            :tone,
            :size,
            :help,
            :classes
          ]
        }
      ],
      examples: [
        %{
          variant: "vertical",
          props: %{"label" => "Plan", "field_name" => "plan", "direction" => "vertical"}
        },
        %{
          variant: "horizontal",
          props: %{"label" => "Size", "field_name" => "size", "direction" => "horizontal"}
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        required: Field.toggle("required", label: "Required"),
        disabled: Field.toggle("disabled", label: "Disabled"),
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
