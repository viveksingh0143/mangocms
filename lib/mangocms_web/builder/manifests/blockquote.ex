defmodule MangoCMSWeb.Builder.Manifests.Blockquote do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "blockquote",
      label: "Blockquote",
      group: "Typography",
      icon: "hero-chat-bubble-left-ellipsis",
      renderer: {TypographyComponents, :blockquote},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "text" => "An inspiring quote or excerpt goes here.",
        "author" => "Author Name",
        "cite" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Left-bordered quote",
          default_props: %{},
          fields: [:text, :author, :cite, :classes]
        }
      ],
      fields: %{
        text: Field.textarea("text", label: "Quote text", bindable: true, required: true),
        author: Field.text("author", label: "Author", bindable: true),
        cite: Field.text("cite", label: "Source / Publication"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
