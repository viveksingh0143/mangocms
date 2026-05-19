defmodule MangoCMSWeb.Builder.Manifests.Badge do
  @moduledoc "Builder manifest for the badge component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "badge",
      label: "Badge",
      group: "Data display",
      icon: "hero-tag",
      renderer: {DisplayComponents, :badge},
      default_variant: "primary",
      accepted_children: [],
      default_props: %{
        "label" => "Badge",
        "tone" => "primary",
        "size" => "md",
        "style" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "primary",
          label: "Primary",
          description: "Solid primary badge",
          default_props: %{"tone" => "primary", "style" => ""},
          fields: [:label, :tone, :size, :classes]
        },
        %{
          id: "outline",
          label: "Outline",
          description: "Outlined badge",
          default_props: %{"style" => "outline"},
          fields: [:label, :tone, :size, :classes]
        },
        %{
          id: "soft",
          label: "Soft",
          description: "Soft tinted badge",
          default_props: %{"style" => "soft"},
          fields: [:label, :tone, :size, :classes]
        }
      ],
      examples: [
        %{variant: "primary", props: %{"label" => "New", "tone" => "primary"}},
        %{variant: "outline", props: %{"label" => "Draft", "tone" => "neutral"}},
        %{variant: "soft", props: %{"label" => "Published", "tone" => "success"}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true, required: true),
        tone:
          Field.select("tone",
            label: "Tone",
            options: [
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Neutral", "neutral"},
              {"Success", "success"},
              {"Warning", "warning"},
              {"Error", "error"},
              {"Info", "info"},
              {"Ghost", "ghost"}
            ]
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
