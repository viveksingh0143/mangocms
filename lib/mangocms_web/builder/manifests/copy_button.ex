defmodule MangoCMSWeb.Builder.Manifests.CopyButton do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.UtilityComponents

  @impl true
  def manifest do
    %{
      name: "copy_button",
      label: "Copy Button",
      group: "Interactive",
      icon: "hero-clipboard",
      renderer: {UtilityComponents, :copy_button},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "value" => "Text to copy",
        "label" => "Copy",
        "copied_label" => "Copied!",
        "style" => "primary",
        "show_value" => false
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "copy_button", owns: ["copied"]},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Copy to clipboard button",
          default_props: %{},
          fields: [:value, :label, :copied_label, :style, :show_value, :classes]
        }
      ],
      fields: %{
        value: Field.text("value", label: "Value to copy", bindable: true, required: true),
        label: Field.text("label", label: "Button label"),
        copied_label: Field.text("copied_label", label: "Copied label"),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Primary", "primary"},
              {"Ghost", "ghost"},
              {"Outline", "outline"}
            ]
          ),
        show_value: Field.toggle("show_value", label: "Show value"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
