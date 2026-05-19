defmodule MangoCMSWeb.Builder.Manifests.Timeline do
  @moduledoc "Builder manifest for timeline data display."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "timeline",
      label: "Timeline",
      group: "Data display",
      icon: "hero-clock",
      renderer: {DisplayComponents, :timeline},
      default_variant: "vertical",
      accepted_children: ["heading", "paragraph", "badge", "icon"],
      default_props: %{
        "collection" => "",
        "direction" => "vertical",
        "compact" => false,
        "date_template" => "{{item.date}}",
        "title_template" => "{{item.title}}",
        "body_template" => "{{item.body}}",
        "icon" => "hero-check-circle"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "items", label: "Items", accepts: ["heading", "paragraph", "badge", "icon"]}
      ],
      variants: [
        %{
          id: "vertical",
          label: "Vertical",
          description: "Vertical timeline",
          fields: [
            :collection,
            :date_template,
            :title_template,
            :body_template,
            :direction,
            :compact,
            :icon,
            :classes,
            :slots
          ],
          slots: ["items"]
        },
        %{
          id: "horizontal",
          label: "Horizontal",
          description: "Horizontal timeline",
          default_props: %{"direction" => "horizontal"},
          fields: [
            :collection,
            :date_template,
            :title_template,
            :body_template,
            :direction,
            :compact,
            :icon,
            :classes,
            :slots
          ],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "vertical", props: %{}},
        %{variant: "horizontal", props: %{"direction" => "horizontal"}}
      ],
      fields: %{
        collection: Field.text("collection", label: "Collection key", bindable: true),
        date_template: Field.text("date_template", label: "Date template", bindable: true),
        title_template: Field.text("title_template", label: "Title template", bindable: true),
        body_template: Field.textarea("body_template", label: "Body template", bindable: true),
        direction:
          Field.select("direction",
            label: "Direction",
            options: [{"Vertical", "vertical"}, {"Horizontal", "horizontal"}]
          ),
        compact: Field.toggle("compact", label: "Compact"),
        icon: Field.icon("icon", label: "Icon"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
