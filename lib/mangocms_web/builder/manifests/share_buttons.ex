defmodule MangoCMSWeb.Builder.Manifests.ShareButtons do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.UtilityComponents

  @impl true
  def manifest do
    %{
      name: "share_buttons",
      label: "Share Buttons",
      group: "Interactive",
      icon: "hero-share",
      renderer: {UtilityComponents, :share_buttons},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "label" => "Share:",
        "text" => "",
        "style" => "ghost",
        "show_labels" => false,
        "platforms" => ["twitter", "linkedin", "copy"]
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "share_buttons", owns: ["url"]},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Social share buttons",
          default_props: %{},
          fields: [:label, :text, :style, :show_labels, :classes]
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label"),
        text: Field.text("text", label: "Share text (Twitter)", bindable: true),
        style:
          Field.select("style",
            label: "Button style",
            options: [
              {"Ghost", "ghost"},
              {"Outline", "outline"},
              {"Filled", "filled"}
            ]
          ),
        show_labels: Field.toggle("show_labels", label: "Show labels"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
