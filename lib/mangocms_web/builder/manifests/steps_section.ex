defmodule MangoCMSWeb.Builder.Manifests.StepsSection do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "steps_section",
      label: "Steps",
      group: "Content",
      icon: "hero-numbered-list",
      renderer: {ContentComponents, :steps_section},
      default_variant: "filled",
      accepted_children: [],
      default_props: %{
        "steps" => [
          %{"title" => "Sign up", "body" => "Create your free account in under a minute."},
          %{"title" => "Connect", "body" => "Link your tools and data sources."},
          %{"title" => "Launch", "body" => "Go live and start growing your business."}
        ],
        "style" => "filled"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "filled",
          label: "Filled",
          description: "Filled number circles",
          default_props: %{"style" => "filled"},
          fields: [:steps, :style, :classes]
        },
        %{
          id: "outline",
          label: "Outline",
          description: "Outlined number circles",
          default_props: %{"style" => "outline"},
          fields: [:steps, :style, :classes]
        },
        %{
          id: "ghost",
          label: "Ghost",
          description: "Subtle number circles",
          default_props: %{"style" => "ghost"},
          fields: [:steps, :style, :classes]
        }
      ],
      fields: %{
        steps: Field.action_list("steps", label: "Steps"),
        style:
          Field.select("style",
            label: "Number style",
            options: [
              {"Filled", "filled"},
              {"Outline", "outline"},
              {"Ghost", "ghost"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
