defmodule MangoCMSWeb.Builder.Manifests.Toggle do
  @moduledoc "Builder manifest for the toggle switch component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "toggle",
      label: "Toggle",
      group: "Data input",
      icon: "hero-adjustments-horizontal",
      renderer: {InputComponents, :toggle},
      default_variant: "label_left",
      accepted_children: [],
      default_props: %{
        "label" => "Enable notifications",
        "field_name" => "notifications",
        "checked" => false,
        "disabled" => false,
        "label_position" => "left",
        "tone" => "",
        "size" => "",
        "help" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "label_left",
          label: "Label left",
          description: "Label appears before the toggle",
          default_props: %{"label_position" => "left"},
          fields: [:label, :field_name, :disabled, :label_position, :tone, :size, :help, :classes]
        },
        %{
          id: "label_right",
          label: "Label right",
          description: "Label appears after the toggle",
          default_props: %{"label_position" => "right"},
          fields: [:label, :field_name, :disabled, :label_position, :tone, :size, :help, :classes]
        }
      ],
      examples: [
        %{
          variant: "label_left",
          props: %{"label" => "Dark mode", "label_position" => "left", "tone" => "primary"}
        },
        %{
          variant: "label_right",
          props: %{"label" => "Subscribe", "label_position" => "right"}
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        disabled: Field.toggle("disabled", label: "Disabled"),
        label_position:
          Field.select("label_position",
            label: "Label position",
            options: [{"Left", "left"}, {"Right", "right"}]
          ),
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
