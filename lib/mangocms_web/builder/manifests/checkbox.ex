defmodule MangoCMSWeb.Builder.Manifests.Checkbox do
  @moduledoc "Builder manifest for the checkbox component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "checkbox",
      label: "Checkbox",
      group: "Data input",
      icon: "hero-check-circle",
      renderer: {InputComponents, :checkbox},
      default_variant: "single",
      accepted_children: [],
      default_props: %{
        "mode" => "single",
        "label" => "Accept terms",
        "field_name" => "accept",
        "checked" => false,
        "required" => false,
        "disabled" => false,
        "tone" => "",
        "size" => "",
        "error" => false,
        "error_message" => "",
        "help" => "",
        "group_label" => "",
        "direction" => "vertical",
        "options" => [
          %{"label" => "Option A", "value" => "a"},
          %{"label" => "Option B", "value" => "b"},
          %{"label" => "Option C", "value" => "c"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "single",
          label: "Single",
          description: "Single checkbox field",
          default_props: %{"mode" => "single"},
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
          id: "group",
          label: "Group",
          description: "Multiple checkbox options",
          default_props: %{"mode" => "group"},
          fields: [
            :group_label,
            :field_name,
            :direction,
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
          variant: "single",
          props: %{"label" => "Accept terms and conditions", "field_name" => "accept"}
        },
        %{
          variant: "group",
          props: %{
            "mode" => "group",
            "group_label" => "Interests",
            "field_name" => "interests"
          }
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        group_label: Field.text("group_label", label: "Group label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        required: Field.toggle("required", label: "Required"),
        disabled: Field.toggle("disabled", label: "Disabled"),
        direction:
          Field.select("direction",
            label: "Direction",
            options: [{"Vertical", "vertical"}, {"Horizontal", "horizontal"}]
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
