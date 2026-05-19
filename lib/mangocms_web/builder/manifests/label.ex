defmodule MangoCMSWeb.Builder.Manifests.Label do
  @moduledoc "Builder manifest for the standalone label component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "label",
      label: "Label",
      group: "Data input",
      icon: "hero-tag",
      renderer: {InputComponents, :label},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "text" => "Field label",
        "alt_text" => "",
        "size" => "",
        "for" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Primary label text only",
          default_props: %{"alt_text" => ""},
          fields: [:text, :size, :classes]
        },
        %{
          id: "with_alt",
          label: "With alt text",
          description: "Primary label with secondary alt text on the right",
          default_props: %{"alt_text" => "Optional"},
          fields: [:text, :alt_text, :size, :classes]
        }
      ],
      examples: [
        %{variant: "default", props: %{"text" => "Email address"}},
        %{
          variant: "with_alt",
          props: %{"text" => "Password", "alt_text" => "Forgot password?"}
        }
      ],
      fields: %{
        text: Field.text("text", label: "Label text", bindable: true, required: true),
        alt_text: Field.text("alt_text", label: "Alt text (right side)", bindable: true),
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
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
