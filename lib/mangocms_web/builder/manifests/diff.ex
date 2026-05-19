defmodule MangoCMSWeb.Builder.Manifests.Diff do
  @moduledoc "Builder manifest for the diff slider component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "diff",
      label: "Diff",
      group: "Data display",
      icon: "hero-arrows-right-left",
      renderer: {DisplayComponents, :diff},
      default_variant: "image",
      accepted_children: [],
      default_props: %{
        "type" => "image",
        "before_src" => "",
        "before_alt" => "Before",
        "after_src" => "",
        "after_alt" => "After",
        "before_text" => "Before",
        "after_text" => "After"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "image",
          label: "Image",
          description: "Side-by-side image comparison",
          default_props: %{"type" => "image"},
          fields: [:before_src, :before_alt, :after_src, :after_alt, :classes]
        },
        %{
          id: "text",
          label: "Text",
          description: "Side-by-side text comparison",
          default_props: %{"type" => "text"},
          fields: [:before_text, :after_text, :classes]
        }
      ],
      examples: [
        %{
          variant: "image",
          props: %{
            "before_src" => "/images/placeholder.svg",
            "after_src" => "/images/placeholder.svg"
          }
        },
        %{variant: "text", props: %{"before_text" => "Before", "after_text" => "After"}}
      ],
      fields: %{
        before_src: Field.media("before_src", label: "Before image", bindable: true),
        before_alt: Field.text("before_alt", label: "Before alt text"),
        after_src: Field.media("after_src", label: "After image", bindable: true),
        after_alt: Field.text("after_alt", label: "After alt text"),
        before_text: Field.text("before_text", label: "Before text", bindable: true),
        after_text: Field.text("after_text", label: "After text", bindable: true),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
