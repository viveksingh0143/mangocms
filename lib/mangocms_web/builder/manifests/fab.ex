defmodule MangoCMSWeb.Builder.Manifests.Fab do
  @moduledoc "Builder manifest for the FAB / speed dial component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ActionComponents

  @impl true
  def manifest do
    %{
      name: "fab",
      label: "FAB / Speed Dial",
      group: "Action",
      icon: "hero-plus-circle",
      renderer: {ActionComponents, :fab},
      default_variant: "single",
      accepted_children: ["button", "anchor"],
      default_props: %{
        "label" => "Create",
        "icon" => "hero-plus",
        "mode" => "single",
        "position" => "bottom_right",
        "size" => "md",
        "button_style" => "btn-primary",
        "actions" => [
          %{"label" => "New page", "href" => "#new-page", "icon" => "hero-document-plus"},
          %{"label" => "Upload", "href" => "#upload", "icon" => "hero-arrow-up-tray"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "fab", owns: ["open"]},
      slots: [
        %{
          id: "actions",
          label: "Speed dial actions",
          accepts: ["button", "anchor"],
          max_children: 6
        }
      ],
      variants: [
        %{
          id: "single",
          label: "Single FAB",
          description: "One floating action button",
          default_props: %{"mode" => "single"},
          fields: [:label, :icon, :position, :size, :button_style, :classes]
        },
        %{
          id: "speed_dial",
          label: "Speed dial",
          description: "Expandable floating action menu",
          default_props: %{"mode" => "speed_dial"},
          fields: [:label, :icon, :position, :size, :button_style, :actions, :classes, :slots],
          slots: ["actions"]
        }
      ],
      examples: [
        %{variant: "single", props: %{"label" => "Create"}},
        %{variant: "speed_dial", props: %{"label" => "Open actions", "mode" => "speed_dial"}}
      ],
      fields: %{
        label: Field.text("label", label: "Accessible label", required: true),
        icon: Field.icon("icon", label: "Icon"),
        position:
          Field.select("position",
            label: "Position",
            options: [
              {"Bottom right", "bottom_right"},
              {"Bottom left", "bottom_left"},
              {"Top right", "top_right"},
              {"Top left", "top_left"}
            ]
          ),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        button_style:
          Field.select("button_style",
            label: "Button style",
            options: [
              {"Primary", "btn-primary"},
              {"Secondary", "btn-secondary"},
              {"Accent", "btn-accent"}
            ]
          ),
        actions: Field.action_list("actions", label: "Actions"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
