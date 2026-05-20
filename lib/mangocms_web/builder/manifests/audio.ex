defmodule MangoCMSWeb.Builder.Manifests.Audio do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MediaComponents

  @impl true
  def manifest do
    %{
      name: "audio",
      label: "Audio",
      group: "Media",
      icon: "hero-musical-note",
      renderer: {MediaComponents, :audio},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "src" => "",
        "controls" => true,
        "autoplay" => false,
        "loop" => false
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Audio player",
          default_props: %{},
          fields: [:src, :controls, :autoplay, :loop, :classes]
        }
      ],
      fields: %{
        src: Field.text("src", label: "Audio URL", required: true, bindable: true),
        controls: Field.toggle("controls", label: "Show controls"),
        autoplay: Field.toggle("autoplay", label: "Autoplay"),
        loop: Field.toggle("loop", label: "Loop"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
