defmodule MangoCMSWeb.Builder.Manifests.NotificationBar do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "notification_bar",
      label: "Notification Bar",
      group: "Content",
      icon: "hero-bell-alert",
      renderer: {ContentComponents, :notification_bar},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "text" => "Your free trial ends in 3 days.",
        "icon" => "hero-bell",
        "link_label" => "Upgrade now",
        "link_href" => "#",
        "cta_label" => "",
        "cta_href" => "",
        "style" => "default"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "notification_bar", owns: ["dismissed"]},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Sticky bottom notification",
          default_props: %{"style" => "default"},
          fields: [:text, :icon, :link_label, :link_href, :cta_label, :cta_href, :style, :classes]
        },
        %{
          id: "warning",
          label: "Warning",
          description: "Warning notification bar",
          default_props: %{"style" => "warning"},
          fields: [:text, :icon, :link_label, :link_href, :cta_label, :cta_href, :style, :classes]
        },
        %{
          id: "info",
          label: "Info",
          description: "Info notification bar",
          default_props: %{"style" => "info"},
          fields: [:text, :icon, :link_label, :link_href, :cta_label, :cta_href, :style, :classes]
        }
      ],
      fields: %{
        text: Field.text("text", label: "Message", bindable: true, required: true),
        icon: Field.icon("icon", label: "Icon"),
        link_label: Field.text("link_label", label: "Link label"),
        link_href: Field.link("link_href", label: "Link URL"),
        cta_label: Field.text("cta_label", label: "Button label"),
        cta_href: Field.link("cta_href", label: "Button URL"),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Default", "default"},
              {"Neutral", "neutral"},
              {"Info", "info"},
              {"Success", "success"},
              {"Warning", "warning"},
              {"Error", "error"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
