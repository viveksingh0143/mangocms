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
        "layout" => "split_left",
        "height" => "standard",
        "content_width" => "wide"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "hero", owns: ["visible"]},
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
          fields: [
            :eyebrow,
            :title,
            :subtitle,
            :layout,
            :height,
            :content_width,
            :classes,
            :slots
          ],
          slots: ["content", "media", "actions"]
        },
        %{
          id: "split_right",
          label: "Split right",
          description: "Text right, media left",
          default_props: %{"layout" => "split_right"},
          fields: [
            :eyebrow,
            :title,
            :subtitle,
            :layout,
            :height,
            :content_width,
            :classes,
            :slots
          ],
          slots: ["content", "media", "actions"]
        },
        %{
          id: "centered",
          label: "Centered",
          description: "Centered text hero",
          default_props: %{"layout" => "centered"},
          fields: [
            :eyebrow,
            :title,
            :subtitle,
            :layout,
            :height,
            :content_width,
            :classes,
            :slots
          ],
          slots: ["content", "actions"]
        },
        %{
          id: "fullscreen",
          label: "Fullscreen",
          description: "Full-height hero for landing pages",
          default_props: %{"height" => "full", "layout" => "centered"},
          fields: [
            :eyebrow,
            :title,
            :subtitle,
            :layout,
            :height,
            :content_width,
            :classes,
            :slots
          ],
          slots: ["content", "actions"]
        }
      ],
      examples: [
        %{
          variant: "split_left",
          props: %{
            "title" => "Launch your tenant website",
            "subtitle" => "Publish pages, catalogs, and content collections from one admin."
          }
        },
        %{
          variant: "split_right",
          props: %{
            "title" => "Local-first content engine",
            "subtitle" => "Fast tenant sites with clean public rendering."
          }
        },
        %{
          variant: "centered",
          props: %{
            "title" => "MangoCMS builder library",
            "subtitle" => "Composable UI blocks backed by Elixir manifests."
          }
        },
        %{
          variant: "fullscreen",
          props: %{
            "title" => "Publish a complete site",
            "subtitle" => "A full viewport opening section with responsive content width."
          }
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
        height:
          Field.select("height",
            label: "Height",
            options: [
              {"Compact", "compact"},
              {"Standard", "standard"},
              {"Fullscreen", "full"}
            ]
          ),
        content_width:
          Field.select("content_width",
            label: "Content width",
            options: [
              {"Narrow", "narrow"},
              {"Default", "default"},
              {"Wide", "wide"},
              {"Full", "full"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
