defmodule MangoCMSWeb.Builder.Manifests.Dock do
  @moduledoc "Builder manifest for dock navigation."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.NavigationComponents

  @impl true
  def manifest do
    %{
      name: "dock",
      label: "Dock",
      group: "Navigation",
      icon: "hero-device-phone-mobile",
      renderer: {NavigationComponents, :dock},
      default_variant: "bottom",
      accepted_children: ["link", "button", "icon"],
      default_props: %{
        "position" => "bottom",
        "active_item" => "home",
        "items" => [
          %{"id" => "home", "label" => "Home", "href" => "/", "icon" => "hero-home"},
          %{
            "id" => "search",
            "label" => "Search",
            "href" => "#search",
            "icon" => "hero-magnifying-glass"
          },
          %{"id" => "account", "label" => "Account", "href" => "#account", "icon" => "hero-user"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "items", label: "Items", accepts: ["link", "button", "icon"], max_children: 5}
      ],
      variants: [
        %{
          id: "bottom",
          label: "Bottom",
          description: "Bottom mobile dock",
          fields: [:items, :active_item, :position, :classes, :slots],
          slots: ["items"]
        },
        %{
          id: "top",
          label: "Top",
          description: "Top dock bar",
          default_props: %{"position" => "top"},
          fields: [:items, :active_item, :position, :classes, :slots],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "bottom", props: %{}},
        %{variant: "top", props: %{"position" => "top", "active_item" => "search"}}
      ],
      fields: %{
        items: Field.action_list("items", label: "Dock items"),
        active_item: Field.text("active_item", label: "Active item ID"),
        position:
          Field.select("position",
            label: "Position",
            options: [{"Bottom", "bottom"}, {"Top", "top"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
