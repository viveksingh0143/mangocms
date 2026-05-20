defmodule MangoCMSWeb.Builder.Manifests.ReadMore do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.UtilityComponents

  @impl true
  def manifest do
    %{
      name: "read_more",
      label: "Read More",
      group: "Interactive",
      icon: "hero-chevron-down",
      renderer: {UtilityComponents, :read_more},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "content" =>
          "<p>This is a longer block of content that gets truncated. Click \"Read more\" to expand the full text and see everything.</p><p>Additional paragraph that is hidden initially.</p>",
        "preview_lines" => "4",
        "more_label" => "Read more",
        "less_label" => "Show less"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "read_more", owns: ["expanded"]},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Expandable content block",
          default_props: %{},
          fields: [:content, :preview_lines, :more_label, :less_label, :classes]
        }
      ],
      fields: %{
        content: Field.textarea("content", label: "HTML Content", bindable: true),
        preview_lines:
          Field.select("preview_lines",
            label: "Preview height",
            options: [
              {"3 lines", "3"},
              {"4 lines", "4"},
              {"6 lines", "6"},
              {"8 lines", "8"}
            ]
          ),
        more_label: Field.text("more_label", label: "Expand label"),
        less_label: Field.text("less_label", label: "Collapse label"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
