defmodule MangoCMSWeb.Builder.Manifests.Input do
  @moduledoc "Builder manifest for the input component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "input",
      label: "Input",
      group: "Data input",
      icon: "hero-pencil-square",
      renderer: {InputComponents, :input},
      default_variant: "text",
      accepted_children: [],
      default_props: %{
        "label" => "Label",
        "field_name" => "field",
        "input_type" => "text",
        "placeholder" => "Type here",
        "required" => false,
        "disabled" => false,
        "style" => "input-bordered",
        "help" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "text",
          label: "Text",
          description: "Single-line text input",
          default_props: %{"input_type" => "text"},
          fields: [
            :label,
            :field_name,
            :input_type,
            :placeholder,
            :required,
            :disabled,
            :style,
            :help,
            :classes
          ]
        },
        %{
          id: "email",
          label: "Email",
          description: "Email input",
          default_props: %{"input_type" => "email", "placeholder" => "you@example.com"},
          fields: [
            :label,
            :field_name,
            :input_type,
            :placeholder,
            :required,
            :disabled,
            :style,
            :help,
            :classes
          ]
        },
        %{
          id: "number",
          label: "Number",
          description: "Numeric input",
          default_props: %{"input_type" => "number", "placeholder" => "0"},
          fields: [
            :label,
            :field_name,
            :input_type,
            :placeholder,
            :required,
            :disabled,
            :style,
            :help,
            :classes
          ]
        }
      ],
      examples: [
        %{variant: "text", props: %{"label" => "Name", "field_name" => "name"}},
        %{variant: "email", props: %{"label" => "Email", "field_name" => "email"}},
        %{variant: "number", props: %{"label" => "Quantity", "field_name" => "quantity"}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        input_type:
          Field.select("input_type",
            label: "Input type",
            options: [
              {"Text", "text"},
              {"Email", "email"},
              {"Number", "number"},
              {"URL", "url"},
              {"Password", "password"}
            ]
          ),
        placeholder: Field.text("placeholder", label: "Placeholder", bindable: true),
        required: Field.toggle("required", label: "Required"),
        disabled: Field.toggle("disabled", label: "Disabled"),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Bordered", "input-bordered"},
              {"Ghost", "input-ghost"},
              {"Primary", "input-primary"}
            ]
          ),
        help: Field.text("help", label: "Help text", bindable: true),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
