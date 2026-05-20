defmodule MangoCMSWeb.Builder.Manifests.Image do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MediaComponents

  @impl true
  def manifest do
    %{
      name: "image",
      label: "Image",
      group: "Media",
      icon: "hero-photo",
      renderer: {MediaComponents, :image},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "src" => "/images/no-image-placeholder.webp",
        "alt" => "",
        "caption" => "",
        "aspect_ratio" => "video",
        "object_fit" => "cover",
        "rounded" => "sm"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Standard image",
          default_props: %{},
          fields: [:src, :alt, :caption, :aspect_ratio, :object_fit, :rounded, :classes]
        },
        %{
          id: "square",
          label: "Square",
          description: "1:1 aspect ratio",
          default_props: %{"aspect_ratio" => "square"},
          fields: [:src, :alt, :caption, :aspect_ratio, :object_fit, :rounded, :classes]
        },
        %{
          id: "portrait",
          label: "Portrait",
          description: "3:4 aspect ratio",
          default_props: %{"aspect_ratio" => "portrait"},
          fields: [:src, :alt, :caption, :aspect_ratio, :object_fit, :rounded, :classes]
        }
      ],
      fields: %{
        src: Field.media("src", label: "Image", required: true),
        alt: Field.text("alt", label: "Alt text", bindable: true),
        caption: Field.text("caption", label: "Caption", bindable: true),
        aspect_ratio:
          Field.select("aspect_ratio",
            label: "Aspect Ratio",
            options: [
              {"Free", ""},
              {"Video (16:9)", "video"},
              {"Square (1:1)", "square"},
              {"Portrait (3:4)", "portrait"},
              {"Wide (21:9)", "wide"}
            ]
          ),
        object_fit:
          Field.select("object_fit",
            label: "Fit",
            options: [
              {"Cover", "cover"},
              {"Contain", "contain"},
              {"Fill", "fill"},
              {"None", "none"}
            ]
          ),
        rounded:
          Field.select("rounded",
            label: "Rounded",
            options: [
              {"None", ""},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"Full", "full"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
