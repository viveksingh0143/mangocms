defmodule MangoCMSWeb.Builder.Manifests.Collapse do
  @moduledoc "Builder manifest for collapse data display."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "collapse",
      label: "Collapse",
      group: "Data display",
      icon: "hero-chevron-up-down",
      renderer: {DisplayComponents, :collapse},
      default_variant: "arrow",
      accepted_children: ["heading", "paragraph", "card", "button"],
      default_props: %{
        "title" => "{{item.title}}",
        "body" => "{{item.body}}",
        "style" => "arrow",
        "default_open" => true
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "collapse", owns: ["open"]},
      slots: [
        %{id: "title", label: "Title", accepts: ["heading", "badge"], max_children: 1},
        %{id: "content", label: "Content", accepts: ["paragraph", "card", "button", "image"]}
      ],
      variants: [
        %{
          id: "arrow",
          label: "Arrow",
          description: "Collapsible panel with arrow",
          fields: [:title, :body, :style, :default_open, :classes, :slots],
          slots: ["title", "content"]
        },
        %{
          id: "plus",
          label: "Plus",
          description: "Collapsible panel with plus",
          default_props: %{"style" => "plus"},
          fields: [:title, :body, :style, :default_open, :classes, :slots],
          slots: ["title", "content"]
        }
      ],
      examples: [
        %{variant: "arrow", props: %{"title" => "Open details"}},
        %{variant: "plus", props: %{"style" => "plus", "title" => "More information"}}
      ],
      fields: %{
        title: Field.text("title", label: "Title", bindable: true, required: true),
        body: Field.textarea("body", label: "Body", bindable: true),
        style:
          Field.select("style",
            label: "Style",
            options: [{"Arrow", "arrow"}, {"Plus", "plus"}, {"Plain", "plain"}]
          ),
        default_open: Field.toggle("default_open", label: "Open by default"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
