defmodule MangoCMSWeb.Builder.Manifests.Button do
  @moduledoc "Builder manifest for the button component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ActionComponents

  @impl true
  def manifest do
    %{
      name: "button",
      label: "Button",
      group: "Action",
      icon: "hero-cursor-arrow-rays",
      renderer: {ActionComponents, :button},
      default_variant: "primary",
      accepted_children: [],
      default_props: %{
        "label" => "Button",
        "href" => "#",
        "target" => "_self",
        "style" => "btn-primary"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "primary",
          label: "Primary",
          description: "Prominent call to action",
          default_props: %{"style" => "btn-primary"},
          fields: [:label, :href, :target, :style, :icon, :classes]
        },
        %{
          id: "ghost",
          label: "Ghost",
          description: "Low-emphasis action",
          default_props: %{"style" => "btn-ghost"},
          fields: [:label, :href, :target, :style, :icon, :classes]
        }
      ],
      examples: [
        %{variant: "primary", props: %{"label" => "Get started", "href" => "/signup"}},
        %{variant: "ghost", props: %{"label" => "Learn more", "href" => "/about"}}
      ],
      fields: %{
        label: Field.text("label", label: "Text", bindable: true, required: true),
        href: Field.link("href", label: "Link", bindable: true),
        target:
          Field.select("target",
            label: "Target",
            options: [{"Same tab", "_self"}, {"New tab", "_blank"}]
          ),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Primary", "btn-primary"},
              {"Secondary", "btn-secondary"},
              {"Accent", "btn-accent"},
              {"Ghost", "btn-ghost"},
              {"Link", "btn-link"}
            ]
          ),
        icon: Field.icon("icon", label: "Icon"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
