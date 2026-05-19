defmodule MangoCMSWeb.Builder.Manifests.Steps do
  @moduledoc "Builder manifest for steps navigation."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.NavigationComponents

  @impl true
  def manifest do
    %{
      name: "steps",
      label: "Steps",
      group: "Navigation",
      icon: "hero-forward",
      renderer: {NavigationComponents, :steps},
      default_variant: "horizontal",
      accepted_children: ["link", "button", "badge"],
      default_props: %{
        "direction" => "horizontal",
        "responsive" => true,
        "active_step" => 2,
        "steps" => [
          %{"label" => "Account"},
          %{"label" => "Profile"},
          %{"label" => "Publish"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "items", label: "Items", accepts: ["link", "button", "badge"], max_children: 8}
      ],
      variants: [
        %{
          id: "horizontal",
          label: "Horizontal",
          description: "Horizontal progress steps",
          fields: [:steps, :active_step, :direction, :responsive, :classes, :slots],
          slots: ["items"]
        },
        %{
          id: "vertical",
          label: "Vertical",
          description: "Vertical progress steps",
          default_props: %{"direction" => "vertical"},
          fields: [:steps, :active_step, :direction, :responsive, :classes, :slots],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "horizontal", props: %{}},
        %{variant: "vertical", props: %{"direction" => "vertical", "active_step" => 3}}
      ],
      fields: %{
        steps: Field.action_list("steps", label: "Step labels"),
        active_step: Field.number("active_step", label: "Active step", min: 1, step: 1),
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
