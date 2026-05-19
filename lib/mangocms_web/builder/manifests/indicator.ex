defmodule MangoCMSWeb.Builder.Manifests.Indicator do
  @moduledoc "Builder manifest for the indicator layout component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "indicator",
      label: "Indicator",
      group: "Layout",
      icon: "hero-bell-alert",
      renderer: {LayoutComponents, :indicator},
      default_variant: "badge",
      accepted_children: ["card", "avatar", "button", "image", "stat"],
      default_props: %{
        "label" => "New",
        "content_label" => "Content",
        "position" => "top_end",
        "tone" => "primary"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "content", label: "Content", accepts: ["card", "avatar", "button", "image"]},
        %{
          id: "indicator",
          label: "Indicator",
          accepts: ["badge", "icon", "text"],
          max_children: 1
        }
      ],
      variants: [
        %{
          id: "badge",
          label: "Badge",
          description: "Badge indicator on content",
          fields: [:label, :position, :tone, :classes, :slots],
          slots: ["content", "indicator"]
        },
        %{
          id: "notification",
          label: "Notification",
          description: "Top-right notification marker",
          default_props: %{"label" => "3", "tone" => "accent"},
          fields: [:label, :position, :tone, :classes, :slots],
          slots: ["content", "indicator"]
        }
      ],
      examples: [
        %{variant: "badge", props: %{"label" => "New"}},
        %{variant: "notification", props: %{"label" => "3"}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        position:
          Field.select("position",
            label: "Position",
            options: [
              {"Top end", "top_end"},
              {"Top start", "top_start"},
              {"Bottom end", "bottom_end"},
              {"Bottom start", "bottom_start"}
            ]
          ),
        tone:
          Field.select("tone",
            label: "Tone",
            options: [
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Success", "success"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
