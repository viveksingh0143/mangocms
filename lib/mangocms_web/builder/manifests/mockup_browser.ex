defmodule MangoCMSWeb.Builder.Manifests.MockupBrowser do
  @moduledoc "Builder manifest for the browser chrome mockup component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MockupComponents

  @impl true
  def manifest do
    %{
      name: "mockup_browser",
      label: "Browser mockup",
      group: "Mockup",
      icon: "hero-computer-desktop",
      renderer: {MockupComponents, :mockup_browser},
      default_variant: "default",
      accepted_children: ["card", "hero", "stat", "table", "list", "image"],
      default_props: %{
        "url" => "https://example.com",
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
          description: "Browser mockup with light chrome",
          default_props: %{"theme" => "light"},
          fields: [:url, :placeholder, :classes, :slots]
        },
        %{
          id: "dark",
          label: "Dark",
          description: "Browser mockup with dark neutral chrome",
          default_props: %{"theme" => "dark"},
          fields: [:url, :placeholder, :classes, :slots]
        }
      ],
      examples: [
        %{
          variant: "default",
          props: %{"url" => "https://myapp.com", "theme" => "light"}
        },
        %{
          variant: "dark",
          props: %{"url" => "https://myapp.com/dashboard", "theme" => "dark"}
        }
      ],
      fields: %{
        url: Field.text("url", label: "URL bar text", bindable: true),
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
