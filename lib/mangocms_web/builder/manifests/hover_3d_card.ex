defmodule MangoCMSWeb.Builder.Manifests.Hover3dCard do
  @moduledoc "Builder manifest for the 3D hover card component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "hover_3d_card",
      label: "3D Hover card",
      group: "Data display",
      icon: "hero-square-3-stack-3d",
      renderer: {DisplayComponents, :hover_3d_card},
      default_variant: "card",
      accepted_children: ["heading", "paragraph", "button", "badge"],
      default_props: %{
        "title" => "3D Card",
        "body" => "Hover to tilt this card in 3D space.",
        "image_src" => "",
        "image_alt" => "",
        "size" => "md"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "hover_3d_card", owns: ["tiltCss"]},
      slots: [
        %{
          id: "content",
          label: "Content",
          accepts: ["heading", "paragraph", "button", "badge"]
        }
      ],
      variants: [
        %{
          id: "card",
          label: "Card",
          description: "3D tilt card with image",
          fields: [:title, :body, :image_src, :image_alt, :size, :classes, :slots],
          slots: ["content"]
        },
        %{
          id: "minimal",
          label: "Minimal",
          description: "3D tilt card without image",
          default_props: %{"image_src" => ""},
          fields: [:title, :body, :size, :classes, :slots],
          slots: ["content"]
        }
      ],
      examples: [
        %{
          variant: "card",
          props: %{"title" => "Hover me", "body" => "Watch the 3D perspective shift."}
        },
        %{
          variant: "minimal",
          props: %{"title" => "Clean card", "body" => "No image, just depth."}
        }
      ],
      fields: %{
        title: Field.text("title", label: "Title", bindable: true),
        body: Field.textarea("body", label: "Body", bindable: true),
        image_src: Field.media("image_src", label: "Image", bindable: true),
        image_alt: Field.text("image_alt", label: "Image alt text"),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
