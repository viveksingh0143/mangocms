defmodule MangoCMSWeb.Builder.Manifests.Status do
  @moduledoc "Builder manifest for the status indicator component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "status",
      label: "Status",
      group: "Data display",
      icon: "hero-signal",
      renderer: {DisplayComponents, :status},
      default_variant: "dot",
      accepted_children: [],
      default_props: %{
        "tone" => "success",
        "size" => "md",
        "label" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "dot",
          label: "Dot only",
          description: "Status dot without label",
          default_props: %{"label" => ""},
          fields: [:tone, :size, :classes]
        },
        %{
          id: "with_label",
          label: "With label",
          description: "Status dot with text label",
          default_props: %{"label" => "Online"},
          fields: [:tone, :size, :label, :classes]
        }
      ],
      examples: [
        %{variant: "dot", props: %{"tone" => "success"}},
        %{variant: "with_label", props: %{"tone" => "success", "label" => "Online"}}
      ],
      fields: %{
        tone:
          Field.select("tone",
            label: "Tone",
            options: [
              {"Success / Online", "success"},
              {"Warning / Away", "warning"},
              {"Error / Busy", "error"},
              {"Info", "info"},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Neutral / Offline", "neutral"}
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
        label: Field.text("label", label: "Label", bindable: true),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
