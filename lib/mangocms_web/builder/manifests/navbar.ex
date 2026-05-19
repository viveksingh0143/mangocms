defmodule MangoCMSWeb.Builder.Manifests.Navbar do
  @moduledoc "Builder manifest for navbar navigation."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.NavigationComponents

  @impl true
  def manifest do
    %{
      name: "navbar",
      label: "Navbar",
      group: "Navigation",
      icon: "hero-bars-3",
      renderer: {NavigationComponents, :navbar},
      default_variant: "standard",
      accepted_children: ["link", "button", "dropdown", "menu", "avatar", "theme_controller"],
      default_props: %{
        "brand_label" => "MangoCMS",
        "brand_href" => "/",
        "active_item" => "features",
        "align" => "center",
        "tone" => "base",
        "sticky" => false,
        "responsive" => true,
        "action_label" => "Get started",
        "action_href" => "#",
        "action_style" => "btn-primary",
        "items" => [
          %{"id" => "features", "label" => "Features", "href" => "#features"},
          %{"id" => "pricing", "label" => "Pricing", "href" => "#pricing"},
          %{"id" => "docs", "label" => "Docs", "href" => "#docs"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "navbar", owns: ["open"]},
      slots: [
        %{id: "brand", label: "Brand", accepts: ["link", "image", "heading"], max_children: 1},
        %{id: "start", label: "Start", accepts: ["link", "menu", "dropdown"]},
        %{id: "center", label: "Center", accepts: ["menu", "link", "dropdown"]},
        %{
          id: "actions",
          label: "Actions",
          accepts: ["button", "dropdown", "avatar", "theme_controller"]
        },
        %{id: "mobile", label: "Mobile", accepts: ["menu", "link", "button"]}
      ],
      variants: [
        %{
          id: "standard",
          label: "Standard",
          description: "Brand, links, and action",
          fields: [
            :brand_label,
            :brand_href,
            :items,
            :active_item,
            :align,
            :tone,
            :sticky,
            :responsive,
            :action_label,
            :action_href,
            :classes,
            :slots
          ],
          slots: ["brand", "start", "center", "actions", "mobile"]
        },
        %{
          id: "centered",
          label: "Centered",
          description: "Centered navigation links",
          default_props: %{"align" => "center"},
          fields: [
            :brand_label,
            :brand_href,
            :items,
            :active_item,
            :align,
            :tone,
            :sticky,
            :responsive,
            :action_label,
            :action_href,
            :classes,
            :slots
          ],
          slots: ["brand", "center", "actions", "mobile"]
        },
        %{
          id: "minimal",
          label: "Minimal",
          description: "Brand and end actions only",
          default_props: %{"items" => []},
          fields: [
            :brand_label,
            :brand_href,
            :tone,
            :sticky,
            :responsive,
            :action_label,
            :action_href,
            :classes,
            :slots
          ],
          slots: ["brand", "actions", "mobile"]
        }
      ],
      examples: [
        %{variant: "standard", props: %{"brand_label" => "Acme"}},
        %{variant: "centered", props: %{"active_item" => "pricing"}},
        %{variant: "minimal", props: %{"action_label" => "Login"}}
      ],
      fields: %{
        brand_label: Field.text("brand_label", label: "Brand label", bindable: true),
        brand_href: Field.link("brand_href", label: "Brand link"),
        items: Field.action_list("items", label: "Navigation items"),
        active_item: Field.text("active_item", label: "Active item ID"),
        align:
          Field.select("align",
            label: "Alignment",
            options: [{"Start", "start"}, {"Center", "center"}, {"End", "end"}]
          ),
        tone:
          Field.select("tone",
            label: "Tone",
            options: [{"Base", "base"}, {"Base 200", "base_200"}, {"Neutral", "neutral"}]
          ),
        sticky: Field.toggle("sticky", label: "Sticky"),
        responsive: Field.toggle("responsive", label: "Responsive mobile menu"),
        action_label: Field.text("action_label", label: "Action label", bindable: true),
        action_href: Field.link("action_href", label: "Action link"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
