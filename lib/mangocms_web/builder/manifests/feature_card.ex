defmodule MangoCMSWeb.Builder.Manifests.FeatureCard do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "feature_card",
      label: "Feature Card",
      group: "Content",
      icon: "hero-bolt",
      renderer: {ContentComponents, :feature_card},
      default_variant: "bordered",
      accepted_children: [],
      default_props: %{
        "icon" => "hero-bolt",
        "icon_color" => "primary",
        "title" => "Feature Title",
        "body" => "Describe this feature or benefit clearly and concisely.",
        "link_label" => "",
        "link_href" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "bordered",
          label: "Bordered",
          description: "Card with border",
          default_props: %{},
          fields: [:icon, :icon_color, :title, :body, :link_label, :link_href, :classes]
        },
        %{
          id: "filled",
          label: "Filled",
          description: "Subtle background fill",
          default_props: %{},
          fields: [:icon, :icon_color, :title, :body, :link_label, :link_href, :classes]
        },
        %{
          id: "ghost",
          label: "Ghost",
          description: "No background",
          default_props: %{},
          fields: [:icon, :icon_color, :title, :body, :link_label, :link_href, :classes]
        }
      ],
      fields: %{
        icon: Field.icon("icon", label: "Icon"),
        icon_color:
          Field.select("icon_color",
            label: "Icon color",
            options: [
              {"Default", "default"},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Success", "success"}
            ]
          ),
        title: Field.text("title", label: "Title", bindable: true, required: true),
        body: Field.textarea("body", label: "Body text", bindable: true),
        link_label: Field.text("link_label", label: "Link label"),
        link_href: Field.link("link_href", label: "Link URL"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
