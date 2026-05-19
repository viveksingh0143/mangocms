defmodule MangoCMSWeb.Builder.Manifests.Stack do
  @moduledoc "Builder manifest for the stack layout component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "stack",
      label: "Stack",
      group: "Layout",
      icon: "hero-square-3-stack-3d",
      renderer: {LayoutComponents, :stack},
      default_variant: "cards",
      accepted_children: ["card", "image", "mockup_window", "mockup_browser"],
      default_props: %{
        "size" => "md"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{
          id: "items",
          label: "Items",
          accepts: ["card", "image", "mockup_window", "mockup_browser"],
          max_children: 5
        }
      ],
      variants: [
        %{
          id: "cards",
          label: "Cards",
          description: "Stacked card composition",
          fields: [:size, :classes, :slots],
          slots: ["items"]
        },
        %{
          id: "media",
          label: "Media",
          description: "Stacked images or previews",
          default_props: %{"size" => "lg"},
          fields: [:size, :classes, :slots],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "cards", props: %{}},
        %{variant: "media", props: %{"size" => "lg"}}
      ],
      fields: %{
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
