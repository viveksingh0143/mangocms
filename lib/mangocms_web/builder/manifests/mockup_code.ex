defmodule MangoCMSWeb.Builder.Manifests.MockupCode do
  @moduledoc "Builder manifest for the terminal / code block mockup component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MockupComponents

  @impl true
  def manifest do
    %{
      name: "mockup_code",
      label: "Code mockup",
      group: "Mockup",
      icon: "hero-command-line",
      renderer: {MockupComponents, :mockup_code},
      default_variant: "terminal",
      accepted_children: [],
      default_props: %{
        "theme" => "dark",
        "lines" => "$|mix phx.server|\n>|starting on port 4000|\n✓|ready|success"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "terminal",
          label: "Terminal",
          description: "Dark terminal-style code block",
          default_props: %{"theme" => "dark"},
          fields: [:lines, :classes]
        },
        %{
          id: "light",
          label: "Light",
          description: "Light-themed code block",
          default_props: %{
            "theme" => "light",
            "lines" => "$|npm install|\n>|added 42 packages|\n✓|done|success"
          },
          fields: [:lines, :classes]
        }
      ],
      examples: [
        %{
          variant: "terminal",
          props: %{
            "theme" => "dark",
            "lines" => "$|mix phx.server|\n>|starting on port 4000|\n✓|ready|success"
          }
        },
        %{
          variant: "light",
          props: %{
            "theme" => "light",
            "lines" => "$|npm install|\n>|added 42 packages|\n✓|done|success"
          }
        }
      ],
      fields: %{
        lines:
          Field.textarea("lines",
            label: "Lines (prefix|code|tone per line)",
            help: "Each line: prefix|code|tone. Tones: success, error, warning, info",
            bindable: false
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
