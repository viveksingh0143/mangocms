defmodule MangoCMSWeb.Builder.Manifests.Embed do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MediaComponents

  @impl true
  def manifest do
    %{
      name: "embed",
      label: "Embed",
      group: "Media",
      icon: "hero-code-bracket-square",
      renderer: {MediaComponents, :embed},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "url" => "",
        "title" => "Embedded content",
        "aspect_ratio" => "video"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "iFrame embed",
          default_props: %{},
          fields: [:url, :title, :aspect_ratio, :classes]
        }
      ],
      fields: %{
        url: Field.text("url", label: "Embed URL", required: true, bindable: true),
        title: Field.text("title", label: "Title (accessibility)"),
        aspect_ratio:
          Field.select("aspect_ratio",
            label: "Aspect Ratio",
            options: [
              {"Video (16:9)", "video"},
              {"Square", "square"},
              {"Portrait (9:16)", "portrait"},
              {"Wide (21:9)", "wide"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
