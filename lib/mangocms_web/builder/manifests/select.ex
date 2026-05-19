defmodule MangoCMSWeb.Builder.Manifests.Select do
  @moduledoc "Builder manifest for the select dropdown component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "select",
      label: "Select",
      group: "Data input",
      icon: "hero-chevron-up-down",
      renderer: {InputComponents, :select},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "label" => "Category",
        "field_name" => "category",
        "placeholder" => "Pick one",
        "required" => false,
        "disabled" => false,
        "multiple" => false,
        "style" => "bordered",
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
          id: "default",
          label: "Single select",
          description: "Standard single-value select",
          default_props: %{"multiple" => false},
          fields: [
            :label,
            :field_name,
            :placeholder,
            :required,
            :disabled,
            :style,
            :size,
            :help,
            :classes
          ]
        },
        %{
          id: "multiple",
          label: "Multi-select",
          description: "Allow multiple selections",
          default_props: %{"multiple" => true},
          fields: [
            :label,
            :field_name,
            :placeholder,
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
        %{variant: "default", props: %{"label" => "Category", "field_name" => "category"}},
        %{variant: "multiple", props: %{"label" => "Tags", "multiple" => true}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        placeholder: Field.text("placeholder", label: "Placeholder", bindable: true),
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
