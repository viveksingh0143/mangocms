defmodule MangoCMSWeb.Builder.Manifests.TableOfContents do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.UtilityComponents

  @impl true
  def manifest do
    %{
      name: "table_of_contents",
      label: "Table of Contents",
      group: "Interactive",
      icon: "hero-list-bullet",
      renderer: {UtilityComponents, :table_of_contents},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "title" => "Contents",
        "aria_label" => "Table of contents",
        "width" => "default",
        "items" => [
          %{"href" => "#introduction", "label" => "Introduction", "level" => "2"},
          %{"href" => "#getting-started", "label" => "Getting Started", "level" => "2"},
          %{"href" => "#conclusion", "label" => "Conclusion", "level" => "2"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Table of contents nav",
          default_props: %{},
          fields: [:title, :items, :width, :classes]
        }
      ],
      fields: %{
        title: Field.text("title", label: "Title"),
        items: Field.action_list("items", label: "TOC items"),
        width:
          Field.select("width",
            label: "Width",
            options: [
              {"Default", "default"},
              {"SM", "sm"},
              {"Full", "full"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
