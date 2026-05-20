defmodule MangoCMSWeb.Builder.Manifests.Video do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MediaComponents

  @impl true
  def manifest do
    %{
      name: "video",
      label: "Video",
      group: "Media",
      icon: "hero-video-camera",
      renderer: {MediaComponents, :video},
      default_variant: "youtube",
      accepted_children: [],
      default_props: %{
        "src" => "",
        "embed_type" => "youtube",
        "title" => "",
        "aspect_ratio" => "video",
        "rounded" => "sm",
        "controls" => true,
        "autoplay" => false,
        "loop" => false
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "youtube",
          label: "YouTube",
          description: "YouTube embed",
          default_props: %{"embed_type" => "youtube"},
          fields: [:src, :title, :aspect_ratio, :rounded, :classes]
        },
        %{
          id: "vimeo",
          label: "Vimeo",
          description: "Vimeo embed",
          default_props: %{"embed_type" => "vimeo"},
          fields: [:src, :title, :aspect_ratio, :rounded, :classes]
        },
        %{
          id: "file",
          label: "File",
          description: "Direct video file",
          default_props: %{"embed_type" => "file"},
          fields: [:src, :controls, :autoplay, :loop, :aspect_ratio, :rounded, :classes]
        }
      ],
      fields: %{
        src: Field.text("src", label: "URL", required: true, bindable: true),
        embed_type:
          Field.select("embed_type",
            label: "Type",
            options: [
              {"YouTube", "youtube"},
              {"Vimeo", "vimeo"},
              {"File", "file"}
            ]
          ),
        title: Field.text("title", label: "Title"),
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
        rounded:
          Field.select("rounded",
            label: "Rounded",
            options: [
              {"None", ""},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"}
            ]
          ),
        controls: Field.toggle("controls", label: "Show controls"),
        autoplay: Field.toggle("autoplay", label: "Autoplay"),
        loop: Field.toggle("loop", label: "Loop"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
