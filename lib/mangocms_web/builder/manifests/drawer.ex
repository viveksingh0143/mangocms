defmodule MangoCMSWeb.Builder.Manifests.Drawer do
  @moduledoc "Builder manifest for the drawer sidebar layout component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.LayoutComponents

  @impl true
  def manifest do
    %{
      name: "drawer",
      label: "Drawer sidebar",
      group: "Layout",
      icon: "hero-bars-3-bottom-left",
      renderer: {LayoutComponents, :drawer},
      default_variant: "left",
      accepted_children: ["menu", "navbar", "card", "button", "link", "list", "paragraph"],
      default_props: %{
        "trigger_label" => "Open sidebar",
        "trigger_icon" => "hero-bars-3",
        "trigger_style" => "btn-primary",
        "sidebar_title" => "Sidebar",
        "title" => "Drawer content",
        "body" => "Add components to the content slot.",
        "placement" => "left",
        "width" => "md",
        "content_width" => "wide"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "drawer", owns: ["open"]},
      slots: [
        %{id: "sidebar", label: "Sidebar", accepts: ["menu", "list", "card", "button"]},
        %{id: "content", label: "Content", accepts: ["hero", "card", "paragraph", "image"]},
        %{id: "actions", label: "Actions", accepts: ["button", "dropdown"], max_children: 3}
      ],
      variants: [
        %{
          id: "left",
          label: "Left sidebar",
          description: "Drawer opens from the left",
          default_props: %{"placement" => "left"},
          fields: [
            :trigger_label,
            :sidebar_title,
            :placement,
            :width,
            :content_width,
            :trigger_style,
            :classes,
            :slots
          ],
          slots: ["sidebar", "content", "actions"]
        },
        %{
          id: "right",
          label: "Right sidebar",
          description: "Drawer opens from the right",
          default_props: %{"placement" => "right"},
          fields: [
            :trigger_label,
            :sidebar_title,
            :placement,
            :width,
            :content_width,
            :trigger_style,
            :classes,
            :slots
          ],
          slots: ["sidebar", "content", "actions"]
        }
      ],
      examples: [
        %{variant: "left", props: %{"sidebar_title" => "Navigation"}},
        %{variant: "right", props: %{"sidebar_title" => "Filters"}}
      ],
      fields: %{
        trigger_label: Field.text("trigger_label", label: "Trigger label", required: true),
        sidebar_title: Field.text("sidebar_title", label: "Sidebar title", bindable: true),
        placement:
          Field.select("placement",
            label: "Placement",
            options: [{"Left", "left"}, {"Right", "right"}]
          ),
        width:
          Field.select("width",
            label: "Sidebar width",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}, {"Extra large", "xl"}]
          ),
        content_width:
          Field.select("content_width",
            label: "Content width",
            options: [
              {"Narrow", "narrow"},
              {"Default", "default"},
              {"Wide", "wide"},
              {"Full", "full"}
            ]
          ),
        trigger_style:
          Field.select("trigger_style",
            label: "Trigger style",
            options: [
              {"Primary", "btn-primary"},
              {"Secondary", "btn-secondary"},
              {"Ghost", "btn-ghost"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
