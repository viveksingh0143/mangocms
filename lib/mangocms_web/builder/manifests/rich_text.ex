defmodule MangoCMSWeb.Builder.Manifests.RichText do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "rich_text",
      label: "Rich Text",
      group: "Typography",
      icon: "hero-document-text",
      renderer: {TypographyComponents, :rich_text},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "content" =>
          "<p>Add your <strong>rich text</strong> content here. Supports <em>HTML</em>.</p>",
        "max_width" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Full prose content",
          default_props: %{},
          fields: [:content, :max_width, :classes]
        },
        %{
          id: "prose",
          label: "Prose",
          description: "Capped prose width",
          default_props: %{"max_width" => "prose"},
          fields: [:content, :max_width, :classes]
        }
      ],
      fields: %{
        content: Field.textarea("content", label: "HTML Content", bindable: true),
        max_width:
          Field.select("max_width",
            label: "Max Width",
            options: [
              {"None", ""},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"XL", "xl"},
              {"Prose", "prose"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
