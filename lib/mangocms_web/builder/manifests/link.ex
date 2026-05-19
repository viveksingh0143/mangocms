defmodule MangoCMSWeb.Builder.Manifests.Link do
  @moduledoc "Builder manifest for navigation links."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.NavigationComponents

  @impl true
  def manifest do
    %{
      name: "link",
      label: "Link",
      group: "Navigation",
      icon: "hero-link",
      renderer: {NavigationComponents, :nav_link},
      default_variant: "text",
      accepted_children: [],
      default_props: %{
        "label" => "Link",
        "href" => "#",
        "target" => "_self",
        "style" => "text",
        "active" => false,
        "icon" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "text",
          label: "Text",
          description: "Inline navigation link",
          default_props: %{"style" => "text"},
          fields: [:label, :href, :target, :style, :active, :icon, :classes]
        },
        %{
          id: "button",
          label: "Button",
          description: "Button-like navigation link",
          default_props: %{"style" => "button"},
          fields: [:label, :href, :target, :style, :active, :icon, :classes]
        },
        %{
          id: "menu_item",
          label: "Menu item",
          description: "Link styled for menus",
          default_props: %{"style" => "menu_item"},
          fields: [:label, :href, :target, :style, :active, :icon, :classes]
        }
      ],
      examples: [
        %{variant: "text", props: %{"label" => "Docs", "href" => "/docs"}},
        %{variant: "button", props: %{"label" => "Start", "href" => "/signup"}},
        %{variant: "menu_item", props: %{"label" => "Settings", "active" => true}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true, required: true),
        href: Field.link("href", label: "Link", bindable: true),
        target:
          Field.select("target",
            label: "Target",
            options: [{"Same tab", "_self"}, {"New tab", "_blank"}]
          ),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Text", "text"},
              {"Button", "button"},
              {"Ghost button", "ghost_button"},
              {"Menu item", "menu_item"}
            ]
          ),
        active: Field.toggle("active", label: "Active"),
        icon: Field.icon("icon", label: "Icon"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
