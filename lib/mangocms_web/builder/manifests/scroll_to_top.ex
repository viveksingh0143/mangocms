defmodule MangoCMSWeb.Builder.Manifests.ScrollToTop do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.UtilityComponents

  @impl true
  def manifest do
    %{
      name: "scroll_to_top",
      label: "Scroll to Top",
      group: "Interactive",
      icon: "hero-arrow-up-circle",
      renderer: {UtilityComponents, :scroll_to_top},
      default_variant: "primary",
      accepted_children: [],
      default_props: %{
        "style" => "primary",
        "threshold" => 300
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "scroll_to_top", owns: ["visible"]},
      slots: [],
      variants: [
        %{
          id: "primary",
          label: "Primary",
          description: "Primary colored button",
          default_props: %{"style" => "primary"},
          fields: [:style, :threshold, :classes]
        },
        %{
          id: "ghost",
          label: "Ghost",
          description: "Ghost style button",
          default_props: %{"style" => "ghost"},
          fields: [:style, :threshold, :classes]
        }
      ],
      fields: %{
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Primary", "primary"},
              {"Neutral", "neutral"},
              {"Ghost", "ghost"}
            ]
          ),
        threshold: Field.number("threshold", label: "Scroll threshold (px)", min: 0, step: 50),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
