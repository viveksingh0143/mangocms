defmodule MangoCMSWeb.Builder.Manifests.Footer do
  @moduledoc "Builder manifest for the footer layout component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "footer",
      label: "Footer",
      group: "Layout",
      icon: "hero-window",
      renderer: {LayoutComponents, :footer},
      default_variant: "standard",
      accepted_children: ["link", "button", "menu", "avatar", "badge", "paragraph"],
      default_props: %{
        "brand" => "MangoCMS",
        "tagline" => "Composable tenant websites with fast publishing.",
        "links_title" => "Links",
        "layout" => "standard",
        "tone" => "base_200",
        "padding" => "normal"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "brand", label: "Brand", accepts: ["image", "heading", "paragraph"]},
        %{id: "links", label: "Links", accepts: ["link", "menu", "button"]},
        %{id: "social", label: "Social", accepts: ["button", "link", "icon"]},
        %{id: "legal", label: "Legal", accepts: ["paragraph", "link"]}
      ],
      variants: [
        %{
          id: "standard",
          label: "Standard",
          description: "Brand and link columns",
          fields: [:brand, :tagline, :links_title, :layout, :tone, :padding, :classes, :slots],
          slots: ["brand", "links", "social", "legal"]
        },
        %{
          id: "centered",
          label: "Centered",
          description: "Centered footer content",
          default_props: %{"layout" => "centered"},
          fields: [:brand, :tagline, :links_title, :layout, :tone, :padding, :classes, :slots],
          slots: ["brand", "links", "social", "legal"]
        },
        %{
          id: "minimal",
          label: "Minimal",
          description: "Compact brand and legal footer",
          default_props: %{"padding" => "compact"},
          fields: [:brand, :tagline, :tone, :padding, :classes, :slots],
          slots: ["brand", "legal"]
        }
      ],
      examples: [
        %{variant: "standard", props: %{"brand" => "Acme Studio"}},
        %{variant: "centered", props: %{"brand" => "MangoCMS"}},
        %{variant: "minimal", props: %{"tagline" => "All rights reserved."}}
      ],
      fields: %{
        brand: Field.text("brand", label: "Brand", bindable: true),
        tagline: Field.textarea("tagline", label: "Tagline", bindable: true),
        links_title: Field.text("links_title", label: "Links title"),
        layout:
          Field.select("layout",
            label: "Layout",
            options: [{"Standard", "standard"}, {"Centered", "centered"}]
          ),
        tone:
          Field.select("tone",
            label: "Tone",
            options: [{"Base", "base"}, {"Base 200", "base_200"}, {"Neutral", "neutral"}]
          ),
        padding:
          Field.select("padding",
            label: "Padding",
            options: [{"Compact", "compact"}, {"Normal", "normal"}, {"Relaxed", "relaxed"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
