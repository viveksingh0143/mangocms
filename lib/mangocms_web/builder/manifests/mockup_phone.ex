defmodule MangoCMSWeb.Builder.Manifests.MockupPhone do
  @moduledoc "Builder manifest for the phone device mockup component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MockupComponents

  @impl true
  def manifest do
    %{
      name: "mockup_phone",
      label: "Phone mockup",
      group: "Mockup",
      icon: "hero-device-phone-mobile",
      renderer: {MockupComponents, :mockup_phone},
      default_variant: "default",
      accepted_children: ["card", "hero", "image", "button", "badge"],
      default_props: %{
        "size" => "1",
        "screen_bg" => "base",
        "placeholder" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{
          id: "screen",
          label: "Screen",
          accepts: ["card", "hero", "image", "button", "badge", "list", "stat"]
        }
      ],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Standard phone mockup (320×568)",
          default_props: %{"size" => "1", "screen_bg" => "base"},
          fields: [:size, :screen_bg, :placeholder, :classes, :slots]
        },
        %{
          id: "large",
          label: "Large",
          description: "Larger phone mockup (414×736)",
          default_props: %{"size" => "3", "screen_bg" => "base"},
          fields: [:size, :screen_bg, :placeholder, :classes, :slots]
        }
      ],
      examples: [
        %{
          variant: "default",
          props: %{"size" => "1", "screen_bg" => "base"}
        },
        %{
          variant: "large",
          props: %{"size" => "3", "screen_bg" => "primary"}
        }
      ],
      fields: %{
        size:
          Field.select("size",
            label: "Phone size",
            options: [
              {"Phone 1 (320×568)", "1"},
              {"Phone 2 (375×667)", "2"},
              {"Phone 3 (414×736)", "3"},
              {"Phone 4 (375×812)", "4"}
            ]
          ),
        screen_bg:
          Field.select("screen_bg",
            label: "Screen background",
            options: [
              {"Base", "base"},
              {"Primary", "primary"},
              {"Neutral", "neutral"}
            ]
          ),
        placeholder:
          Field.text("placeholder",
            label: "Screen placeholder text",
            bindable: true
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
