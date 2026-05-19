defmodule MangoCMSWeb.Builder.Manifests.FileInput do
  @moduledoc "Builder manifest for the file input component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "file_input",
      label: "File input",
      group: "Data input",
      icon: "hero-paper-clip",
      renderer: {InputComponents, :file_input},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "label" => "Attach file",
        "field_name" => "file",
        "accept" => "",
        "multiple" => false,
        "required" => false,
        "disabled" => false,
        "style" => "bordered",
        "size" => "",
        "help" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Standard file picker",
          default_props: %{"multiple" => false},
          fields: [
            :label,
            :field_name,
            :accept,
            :required,
            :disabled,
            :style,
            :size,
            :help,
            :classes
          ]
        },
        %{
          id: "image",
          label: "Image",
          description: "Image upload restricted to common image types",
          default_props: %{"accept" => "image/*", "multiple" => false},
          fields: [
            :label,
            :field_name,
            :accept,
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
        %{variant: "default", props: %{"label" => "Attach file", "accept" => ""}},
        %{variant: "image", props: %{"label" => "Upload photo", "accept" => "image/*"}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        accept:
          Field.text("accept",
            label: "Accepted types",
            placeholder: "image/*, .pdf, .docx"
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
