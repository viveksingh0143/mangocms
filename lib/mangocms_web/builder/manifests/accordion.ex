defmodule MangoCMSWeb.Builder.Manifests.Accordion do
  @moduledoc "Builder manifest for accordion data display."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "accordion",
      label: "Accordion",
      group: "Data display",
      icon: "hero-bars-3-bottom-left",
      renderer: {DisplayComponents, :accordion},
      default_variant: "arrow",
      accepted_children: ["heading", "paragraph", "card", "button"],
      default_props: %{
        "style" => "arrow",
        "spacing" => "joined",
        "default_open" => "accordion_1",
        "collection" => "",
        "title_template" => "{{item.title}}",
        "body_template" => "{{item.body}}",
        "items" => [
          %{
            "id" => "accordion_1",
            "title" => "How does collection binding work?",
            "body" => "Use {{item.field}} placeholders in display fields."
          },
          %{
            "id" => "accordion_2",
            "title" => "Can I use fixed data?",
            "body" => "Yes, fixed items can live directly in props."
          }
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "accordion", owns: ["open"]},
      slots: [
        %{id: "items", label: "Items", accepts: ["heading", "paragraph", "card", "button"]}
      ],
      variants: [
        %{
          id: "arrow",
          label: "Arrow",
          description: "Accordion with arrow indicator",
          fields: [
            :items,
            :collection,
            :title_template,
            :body_template,
            :style,
            :spacing,
            :default_open,
            :classes,
            :slots
          ],
          slots: ["items"]
        },
        %{
          id: "plus",
          label: "Plus",
          description: "Accordion with plus indicator",
          default_props: %{"style" => "plus"},
          fields: [
            :items,
            :collection,
            :title_template,
            :body_template,
            :style,
            :spacing,
            :default_open,
            :classes,
            :slots
          ],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "arrow", props: %{}},
        %{variant: "plus", props: %{"style" => "plus"}}
      ],
      fields: %{
        items: Field.action_list("items", label: "Preview items"),
        collection: Field.text("collection", label: "Collection key", bindable: true),
        title_template: Field.text("title_template", label: "Title template", bindable: true),
        body_template: Field.textarea("body_template", label: "Body template", bindable: true),
        style:
          Field.select("style",
            label: "Style",
            options: [{"Arrow", "arrow"}, {"Plus", "plus"}, {"Plain", "plain"}]
          ),
        spacing:
          Field.select("spacing",
            label: "Spacing",
            options: [{"Joined", "joined"}, {"Separated", "separated"}]
          ),
        default_open: Field.text("default_open", label: "Default open item ID"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
