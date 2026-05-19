defmodule MangoCMSWeb.Builder.Manifests.Validator do
  @moduledoc "Builder manifest for the daisyUI validator input component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "validator",
      label: "Validator",
      group: "Data input",
      icon: "hero-shield-check",
      renderer: {InputComponents, :validator},
      default_variant: "required",
      accepted_children: [],
      default_props: %{
        "label" => "Username",
        "field_name" => "username",
        "input_type" => "text",
        "placeholder" => "Type here…",
        "required" => true,
        "min_length" => "",
        "max_length" => "",
        "pattern" => "",
        "hint" => "Required.",
        "success_message" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "required",
          label: "Required",
          description: "Simple required-field validator",
          default_props: %{"required" => true, "hint" => "This field is required."},
          fields: [:label, :field_name, :input_type, :placeholder, :required, :hint, :classes]
        },
        %{
          id: "pattern",
          label: "Pattern",
          description: "Validates against a regex pattern",
          default_props: %{
            "pattern" => "[a-zA-Z0-9]+",
            "hint" => "Only letters and numbers allowed.",
            "success_message" => "Looks good!"
          },
          fields: [
            :label,
            :field_name,
            :input_type,
            :placeholder,
            :required,
            :min_length,
            :max_length,
            :pattern,
            :hint,
            :success_message,
            :classes
          ]
        }
      ],
      examples: [
        %{
          variant: "required",
          props: %{"label" => "Email", "input_type" => "email", "hint" => "Required."}
        },
        %{
          variant: "pattern",
          props: %{
            "label" => "Username",
            "pattern" => "[a-zA-Z0-9]+",
            "hint" => "Only letters and numbers.",
            "success_message" => "Looks good!"
          }
        }
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
              {"URL", "url"},
              {"Number", "number"},
              {"Password", "password"}
            ]
          ),
        placeholder: Field.text("placeholder", label: "Placeholder", bindable: true),
        required: Field.toggle("required", label: "Required"),
        min_length: Field.text("min_length", label: "Min length"),
        max_length: Field.text("max_length", label: "Max length"),
        pattern: Field.text("pattern", label: "Pattern (regex)"),
        hint: Field.text("hint", label: "Hint / error message", bindable: true),
        success_message: Field.text("success_message", label: "Success message", bindable: true),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
