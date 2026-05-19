defmodule MangoCMSWeb.Builder.Manifests.Swap do
  @moduledoc "Builder manifest for the swap component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ActionComponents

  @impl true
  def manifest do
    %{
      name: "swap",
      label: "Swap",
      group: "Action",
      icon: "hero-arrows-right-left",
      renderer: {ActionComponents, :swap},
      default_variant: "icon",
      accepted_children: ["icon", "button", "image"],
      default_props: %{
        "label" => "Toggle",
        "effect" => "rotate",
        "default_on" => false,
        "on_icon" => "hero-check",
        "off_icon" => "hero-x-mark"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "swap", owns: ["active"]},
      slots: [
        %{id: "on", label: "On state", accepts: ["icon", "button", "image"], max_children: 1},
        %{id: "off", label: "Off state", accepts: ["icon", "button", "image"], max_children: 1}
      ],
      variants: [
        %{
          id: "icon",
          label: "Icon swap",
          description: "Toggle between two icons",
          fields: [:label, :effect, :default_on, :on_icon, :off_icon, :classes, :slots],
          slots: ["on", "off"]
        },
        %{
          id: "rotate",
          label: "Rotate",
          description: "Rotating swap animation",
          default_props: %{"effect" => "rotate"},
          fields: [:label, :effect, :default_on, :on_icon, :off_icon, :classes, :slots],
          slots: ["on", "off"]
        },
        %{
          id: "flip",
          label: "Flip",
          description: "Flipping swap animation",
          default_props: %{"effect" => "flip"},
          fields: [:label, :effect, :default_on, :on_icon, :off_icon, :classes, :slots],
          slots: ["on", "off"]
        }
      ],
      examples: [
        %{variant: "icon", props: %{"label" => "Toggle state"}},
        %{
          variant: "rotate",
          props: %{"effect" => "rotate", "on_icon" => "hero-sun", "off_icon" => "hero-moon"}
        },
        %{
          variant: "flip",
          props: %{"effect" => "flip", "on_icon" => "hero-heart", "off_icon" => "hero-heart"}
        }
      ],
      fields: %{
        label: Field.text("label", label: "Accessible label", required: true),
        effect:
          Field.select("effect",
            label: "Effect",
            options: [{"None", "none"}, {"Rotate", "rotate"}, {"Flip", "flip"}]
          ),
        default_on: Field.toggle("default_on", label: "Start active"),
        on_icon: Field.icon("on_icon", label: "On icon"),
        off_icon: Field.icon("off_icon", label: "Off icon"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
