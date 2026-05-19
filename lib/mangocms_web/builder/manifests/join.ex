defmodule MangoCMSWeb.Builder.Manifests.Join do
  @moduledoc "Builder manifest for the join layout component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "join",
      label: "Join",
      group: "Layout",
      icon: "hero-queue-list",
      renderer: {LayoutComponents, :join},
      default_variant: "horizontal",
      accepted_children: ["button", "input", "select", "dropdown", "swap"],
      default_props: %{
        "direction" => "horizontal",
        "responsive" => true
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{
          id: "items",
          label: "Items",
          accepts: ["button", "input", "select", "dropdown", "swap"],
          max_children: 8
        }
      ],
      variants: [
        %{
          id: "horizontal",
          label: "Horizontal",
          description: "Joined controls in a row",
          default_props: %{"direction" => "horizontal"},
          fields: [:direction, :responsive, :classes, :slots],
          slots: ["items"]
        },
        %{
          id: "vertical",
          label: "Vertical",
          description: "Joined controls in a column",
          default_props: %{"direction" => "vertical"},
          fields: [:direction, :responsive, :classes, :slots],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "horizontal", props: %{}},
        %{variant: "vertical", props: %{}}
      ],
      fields: %{
        direction:
          Field.select("direction",
            label: "Direction",
            options: [{"Horizontal", "horizontal"}, {"Vertical", "vertical"}]
          ),
        responsive: Field.toggle("responsive", label: "Stack on mobile"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
