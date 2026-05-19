defmodule MangoCMSWeb.Builder.Manifests.MockupWindow do
  @moduledoc "Builder manifest for the desktop window chrome mockup component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MockupComponents

  @impl true
  def manifest do
    %{
      name: "mockup_window",
      label: "Window mockup",
      group: "Mockup",
      icon: "hero-rectangle-stack",
      renderer: {MockupComponents, :mockup_window},
      default_variant: "default",
      accepted_children: ["card", "hero", "stat", "table", "list", "image"],
      default_props: %{
        "theme" => "light",
        "placeholder" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{
          id: "content",
          label: "Content",
          accepts: ["card", "hero", "stat", "table", "list", "image", "button", "badge"]
        }
      ],
      variants: [
        %{
          id: "default",
          label: "Light",
          description: "Window mockup with light chrome",
          default_props: %{"theme" => "light"},
          fields: [:placeholder, :classes, :slots]
        },
        %{
          id: "dark",
          label: "Dark",
          description: "Window mockup with dark neutral chrome",
          default_props: %{"theme" => "dark"},
          fields: [:placeholder, :classes, :slots]
        }
      ],
      examples: [
        %{
          variant: "default",
          props: %{"theme" => "light"}
        },
        %{
          variant: "dark",
          props: %{"theme" => "dark"}
        }
      ],
      fields: %{
        placeholder:
          Field.text("placeholder",
            label: "Body placeholder text",
            bindable: true
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
