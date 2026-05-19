defmodule MangoCMSWeb.Builder.Manifests.Hero do
  @moduledoc "Builder manifest for the hero component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "hero",
      label: "Hero",
      group: "Layout",
      icon: "hero-rectangle-group",
      renderer: {LayoutComponents, :hero},
      default_variant: "split_left",
      accepted_children: ["heading", "paragraph", "button", "anchor", "image"],
      default_props: %{
        "eyebrow" => "MangoCMS",
        "title" => "Build faster tenant websites",
        "subtitle" => "Composable sections, collections, and publishing tools.",
        "layout" => "split_left"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "content", label: "Content", accepts: ["heading", "paragraph", "badge", "list"]},
        %{id: "media", label: "Media", accepts: ["image", "video"], max_children: 1},
        %{id: "actions", label: "Actions", accepts: ["button", "anchor"], max_children: 3}
      ],
      variants: [
        %{
          id: "split_left",
          label: "Split left",
          description: "Text left, media right",
          default_props: %{"layout" => "split_left"},
          fields: [:eyebrow, :title, :subtitle, :layout, :classes, :slots],
          slots: ["content", "media", "actions"]
        },
        %{
          id: "split_right",
          label: "Split right",
          description: "Text right, media left",
          default_props: %{"layout" => "split_right"},
          fields: [:eyebrow, :title, :subtitle, :layout, :classes, :slots],
          slots: ["content", "media", "actions"]
        },
        %{
          id: "centered",
          label: "Centered",
          description: "Centered text hero",
          default_props: %{"layout" => "centered"},
          fields: [:eyebrow, :title, :subtitle, :layout, :classes, :slots],
          slots: ["content", "actions"]
        }
      ],
      fields: %{
        eyebrow: Field.text("eyebrow", label: "Eyebrow", bindable: true),
        title: Field.text("title", label: "Title", bindable: true, required: true),
        subtitle: Field.textarea("subtitle", label: "Subtitle", bindable: true),
        layout:
          Field.select("layout",
            label: "Layout",
            options: [
              {"Split left", "split_left"},
              {"Split right", "split_right"},
              {"Centered", "centered"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
