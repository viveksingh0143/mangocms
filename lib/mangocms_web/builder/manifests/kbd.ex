defmodule MangoCMSWeb.Builder.Manifests.Kbd do
  @moduledoc "Builder manifest for the keyboard key component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "kbd",
      label: "Kbd",
      group: "Data display",
      icon: "hero-command-line",
      renderer: {DisplayComponents, :kbd},
      default_variant: "shortcut",
      accepted_children: [],
      default_props: %{
        "keys" => "ctrl+K",
        "size" => "md"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "shortcut",
          label: "Shortcut",
          description: "Multi-key keyboard shortcut",
          default_props: %{"keys" => "ctrl+K"},
          fields: [:keys, :size, :classes]
        },
        %{
          id: "single",
          label: "Single key",
          description: "Single keyboard key",
          default_props: %{"keys" => "Enter"},
          fields: [:keys, :size, :classes]
        }
      ],
      examples: [
        %{variant: "shortcut", props: %{"keys" => "ctrl+shift+K"}},
        %{variant: "single", props: %{"keys" => "Enter"}}
      ],
      fields: %{
        keys:
          Field.text("keys",
            label: "Keys (+ separated)",
            placeholder: "ctrl+K or Enter",
            bindable: true
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"Extra small", "xs"},
              {"Small", "sm"},
              {"Medium", "md"},
              {"Large", "lg"},
              {"Extra large", "xl"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
