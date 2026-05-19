defmodule MangoCMSWeb.Builder.Manifests.Stat do
  @moduledoc "Builder manifest for stat data display."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "stat",
      label: "Stat",
      group: "Data display",
      icon: "hero-chart-bar",
      renderer: {DisplayComponents, :stat},
      default_variant: "single",
      accepted_children: ["icon", "button", "link"],
      default_props: %{
        "label" => "{{item.label}}",
        "value" => "{{item.value}}",
        "description" => "{{item.description}}",
        "icon" => "hero-chart-bar",
        "style" => "shadow-sm",
        "orientation" => "horizontal"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "figure", label: "Figure", accepts: ["icon", "image"], max_children: 1},
        %{id: "actions", label: "Actions", accepts: ["button", "link"], max_children: 2}
      ],
      variants: [
        %{
          id: "single",
          label: "Single",
          description: "One stat card",
          fields: [:label, :value, :description, :icon, :style, :orientation, :classes, :slots],
          slots: ["figure", "actions"]
        },
        %{
          id: "vertical",
          label: "Vertical",
          description: "Vertical stat layout",
          default_props: %{"orientation" => "vertical"},
          fields: [:label, :value, :description, :icon, :style, :orientation, :classes, :slots],
          slots: ["figure", "actions"]
        }
      ],
      examples: [
        %{
          variant: "single",
          props: %{"label" => "Tenants", "value" => "1.2k", "description" => "Active sites"}
        },
        %{
          variant: "vertical",
          props: %{"orientation" => "vertical", "label" => "Reviews", "value" => "98%"}
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        value: Field.text("value", label: "Value", bindable: true),
        description: Field.text("description", label: "Description", bindable: true),
        icon: Field.icon("icon", label: "Icon"),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Shadow", "shadow-sm"},
              {"Bordered", "border border-base-300"},
              {"Plain", ""}
            ]
          ),
        orientation:
          Field.select("orientation",
            label: "Orientation",
            options: [{"Horizontal", "horizontal"}, {"Vertical", "vertical"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
