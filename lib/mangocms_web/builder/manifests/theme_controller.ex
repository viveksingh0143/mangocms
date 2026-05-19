defmodule MangoCMSWeb.Builder.Manifests.ThemeController do
  @moduledoc "Builder manifest for the theme controller component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ActionComponents

  @impl true
  def manifest do
    %{
      name: "theme_controller",
      label: "Theme Controller",
      group: "Action",
      icon: "hero-swatch",
      renderer: {ActionComponents, :theme_controller},
      default_variant: "buttons",
      accepted_children: [],
      default_props: %{
        "default_theme" => "light",
        "themes" => ["light", "dark", "cupcake"],
        "style" => "buttons"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "theme_controller", owns: ["theme"], persists: "mango_theme"},
      slots: [],
      variants: [
        %{
          id: "buttons",
          label: "Buttons",
          description: "Theme choices as joined buttons",
          default_props: %{"style" => "buttons"},
          fields: [:default_theme, :themes, :classes]
        },
        %{
          id: "light_dark",
          label: "Light / dark",
          description: "Two theme toggle",
          default_props: %{"themes" => ["light", "dark"]},
          fields: [:default_theme, :themes, :classes]
        }
      ],
      examples: [
        %{variant: "buttons", props: %{"themes" => ["light", "dark", "cupcake"]}},
        %{variant: "light_dark", props: %{"themes" => ["light", "dark"]}}
      ],
      fields: %{
        default_theme:
          Field.select("default_theme",
            label: "Default theme",
            options: [{"Light", "light"}, {"Dark", "dark"}, {"Cupcake", "cupcake"}]
          ),
        themes: Field.action_list("themes", label: "Theme names"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
