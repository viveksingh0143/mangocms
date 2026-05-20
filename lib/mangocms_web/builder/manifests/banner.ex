defmodule MangoCMSWeb.Builder.Manifests.Banner do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "banner",
      label: "Banner",
      group: "Content",
      icon: "hero-bell",
      renderer: {ContentComponents, :banner},
      default_variant: "primary",
      accepted_children: [],
      default_props: %{
        "text" => "🎉 We just launched something new! Check it out.",
        "icon" => "",
        "link_label" => "Learn more",
        "link_href" => "#",
        "style" => "primary",
        "dismissible" => true
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "banner", owns: ["dismissed"]},
      slots: [],
      variants: [
        %{
          id: "primary",
          label: "Primary",
          description: "Primary brand banner",
          default_props: %{"style" => "primary"},
          fields: [:text, :icon, :link_label, :link_href, :style, :dismissible, :classes]
        },
        %{
          id: "info",
          label: "Info",
          description: "Informational banner",
          default_props: %{"style" => "info"},
          fields: [:text, :icon, :link_label, :link_href, :style, :dismissible, :classes]
        },
        %{
          id: "success",
          label: "Success",
          description: "Success announcement",
          default_props: %{"style" => "success"},
          fields: [:text, :icon, :link_label, :link_href, :style, :dismissible, :classes]
        },
        %{
          id: "warning",
          label: "Warning",
          description: "Warning notice",
          default_props: %{"style" => "warning"},
          fields: [:text, :icon, :link_label, :link_href, :style, :dismissible, :classes]
        }
      ],
      fields: %{
        text: Field.text("text", label: "Banner text", bindable: true, required: true),
        icon: Field.icon("icon", label: "Icon"),
        link_label: Field.text("link_label", label: "Link label"),
        link_href: Field.link("link_href", label: "Link URL"),
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Primary", "primary"},
              {"Info", "info"},
              {"Success", "success"},
              {"Warning", "warning"},
              {"Error", "error"}
            ]
          ),
        dismissible: Field.toggle("dismissible", label: "Dismissible"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
