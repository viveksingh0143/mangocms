defmodule MangoCMSWeb.Builder.Manifests.Menu do
  @moduledoc "Builder manifest for menu navigation."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.NavigationComponents

  @impl true
  def manifest do
    %{
      name: "menu",
      label: "Menu",
      group: "Navigation",
      icon: "hero-list-bullet",
      renderer: {NavigationComponents, :menu},
      default_variant: "vertical",
      accepted_children: ["link", "button", "dropdown", "badge", "icon"],
      default_props: %{
        "direction" => "vertical",
        "size" => "md",
        "active_item" => "dashboard",
        "items" => [
          %{
            "id" => "dashboard",
            "label" => "Dashboard",
            "href" => "#dashboard",
            "icon" => "hero-squares-2x2"
          },
          %{
            "id" => "collections",
            "label" => "Collections",
            "href" => "#collections",
            "icon" => "hero-circle-stack"
          },
          %{
            "id" => "settings",
            "label" => "Settings",
            "href" => "#settings",
            "icon" => "hero-cog-6-tooth"
          }
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "menu", owns: ["active"]},
      slots: [
        %{id: "items", label: "Items", accepts: ["link", "button", "dropdown", "badge", "icon"]}
      ],
      variants: [
        %{
          id: "vertical",
          label: "Vertical",
          description: "Sidebar style menu",
          default_props: %{"direction" => "vertical"},
          fields: [:items, :active_item, :direction, :size, :classes, :slots],
          slots: ["items"]
        },
        %{
          id: "horizontal",
          label: "Horizontal",
          description: "Inline menu row",
          default_props: %{"direction" => "horizontal"},
          fields: [:items, :active_item, :direction, :size, :classes, :slots],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "vertical", props: %{}},
        %{
          variant: "horizontal",
          props: %{"direction" => "horizontal", "active_item" => "collections"}
        }
      ],
      fields: %{
        items: Field.action_list("items", label: "Menu items"),
        active_item: Field.text("active_item", label: "Active item ID"),
        direction:
          Field.select("direction",
            label: "Direction",
            options: [{"Vertical", "vertical"}, {"Horizontal", "horizontal"}]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
