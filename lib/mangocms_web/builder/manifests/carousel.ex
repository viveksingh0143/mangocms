defmodule MangoCMSWeb.Builder.Manifests.Carousel do
  @moduledoc "Builder manifest for the carousel component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "carousel",
      label: "Carousel",
      group: "Data display",
      icon: "hero-arrows-right-left",
      renderer: {DisplayComponents, :carousel},
      default_variant: "slider",
      accepted_children: ["card", "image", "hero", "section"],
      default_props: %{
        "transition" => "slide",
        "items_count" => 3,
        "controls_enabled" => true,
        "items_visible_desktop" => 1
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "carousel", owns: ["active", "total"]},
      slots: [
        %{id: "items", label: "Items", accepts: ["card", "image", "hero", "section"]}
      ],
      variants: [
        %{
          id: "slider",
          label: "Slider",
          description: "Single visible item with controls",
          default_props: %{"items_visible_desktop" => 1, "transition" => "slide"},
          fields: [
            :transition,
            :items_count,
            :items_visible_desktop,
            :controls_enabled,
            :classes,
            :slots
          ],
          slots: ["items"]
        },
        %{
          id: "fade",
          label: "Fade",
          description: "Single visible item with fade transition",
          default_props: %{"items_visible_desktop" => 1, "transition" => "fade"},
          fields: [
            :transition,
            :items_count,
            :items_visible_desktop,
            :controls_enabled,
            :classes,
            :slots
          ],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "slider", props: %{"items_count" => 3}},
        %{variant: "fade", props: %{"items_count" => 2, "transition" => "fade"}}
      ],
      fields: %{
        transition:
          Field.select("transition",
            label: "Transition",
            options: [{"Slide", "slide"}, {"Fade", "fade"}]
          ),
        items_count: Field.number("items_count", label: "Preview items", min: 1, max: 12),
        items_visible_desktop:
          Field.number("items_visible_desktop", label: "Items visible on desktop", min: 1, max: 6),
        controls_enabled: Field.toggle("controls_enabled", label: "Show controls"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
