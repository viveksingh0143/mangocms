defmodule MangoCMSWeb.Builder.Manifests.Textarea do
  @moduledoc "Builder manifest for the textarea component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "textarea",
      label: "Textarea",
      group: "Data input",
      icon: "hero-bars-3-bottom-left",
      renderer: {InputComponents, :textarea},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "label" => "Message",
        "field_name" => "message",
        "placeholder" => "Type here…",
        "rows" => 4,
        "required" => false,
        "disabled" => false,
        "style" => "bordered",
        "size" => "",
        "error" => false,
        "error_message" => "",
        "help" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Standard bordered textarea",
          default_props: %{"style" => "bordered"},
          fields: [
            :label,
            :field_name,
            :placeholder,
            :rows,
            :required,
            :disabled,
            :style,
            :size,
            :help,
            :classes
          ]
        },
        %{
          id: "ghost",
          label: "Ghost",
          description: "Minimal ghost-style textarea",
          default_props: %{"style" => "ghost"},
          fields: [
            :label,
            :field_name,
            :placeholder,
            :rows,
            :required,
            :disabled,
            :style,
            :size,
            :help,
            :classes
          ]
        }
      ],
      examples: [
        %{
          variant: "default",
          props: %{"label" => "Message", "placeholder" => "Write something…"}
        },
        %{variant: "ghost", props: %{"label" => "Notes", "style" => "ghost"}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        placeholder: Field.text("placeholder", label: "Placeholder", bindable: true),
        rows:
          Field.number("rows",
            label: "Rows",
            min: 2,
            max: 20
          ),
        required: Field.toggle("required", label: "Required"),
        disabled: Field.toggle("disabled", label: "Disabled"),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Bordered", "bordered"},
              {"Ghost", "ghost"},
              {"Primary", "primary"}
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
