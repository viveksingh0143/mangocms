defmodule MangoCMSWeb.Builder.Manifests.Card do
  @moduledoc "Builder manifest for the card component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "card",
      label: "Card",
      group: "Data display",
      icon: "hero-rectangle-stack",
      renderer: {DisplayComponents, :card},
      default_variant: "image_top",
      accepted_children: ["image", "heading", "paragraph", "button", "anchor"],
      default_props: %{
        "title" => "Card title",
        "body" => "Card body",
        "image_enabled" => true,
        "image_position" => "top",
        "image_src" => "",
        "image_alt" => "",
        "style" => "shadow-sm"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "media", label: "Media", accepts: ["image", "video"], max_children: 1},
        %{id: "body", label: "Body", accepts: ["heading", "paragraph", "badge", "list"]},
        %{id: "actions", label: "Actions", accepts: ["button", "anchor"], max_children: 3}
      ],
      variants: [
        %{
          id: "image_top",
          label: "Image top",
          description: "Image above the body",
          default_props: %{"image_enabled" => true, "image_position" => "top"},
          fields: [
            :title,
            :body,
            :image_enabled,
            :image_src,
            :image_alt,
            :style,
            :classes,
            :slots
          ],
          slots: ["media", "body", "actions"]
        },
        %{
          id: "image_bottom",
          label: "Image bottom",
          description: "Image below the body",
          default_props: %{"image_enabled" => true, "image_position" => "bottom"},
          fields: [
            :title,
            :body,
            :image_enabled,
            :image_src,
            :image_alt,
            :style,
            :classes,
            :slots
          ],
          slots: ["media", "body", "actions"]
        },
        %{
          id: "plain",
          label: "Plain",
          description: "Text-only card",
          default_props: %{"image_enabled" => false},
          fields: [:title, :body, :style, :classes, :slots],
          slots: ["body", "actions"]
        }
      ],
      fields: %{
        title: Field.text("title", label: "Title", bindable: true, required: true),
        body: Field.textarea("body", label: "Body", bindable: true),
        image_enabled: Field.toggle("image_enabled", label: "Show image"),
        image_src: Field.media("image_src", label: "Image", bindable: true),
        image_alt: Field.text("image_alt", label: "Image alt text", bindable: true),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Shadow", "shadow-sm"},
              {"Bordered", "border border-base-300"},
              {"Glass", "glass"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
