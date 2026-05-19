defmodule MangoCMSWeb.Builder.Manifests.Avatar do
  @moduledoc "Builder manifest for the avatar component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "avatar",
      label: "Avatar",
      group: "Data display",
      icon: "hero-user-circle",
      renderer: {DisplayComponents, :avatar},
      default_variant: "single",
      accepted_children: ["image"],
      default_props: %{
        "image_src" => "",
        "initials" => "AB",
        "alt" => "",
        "size" => "md",
        "shape" => "circle",
        "status" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "image", label: "Image", accepts: ["image"], max_children: 1}
      ],
      variants: [
        %{
          id: "single",
          label: "Single",
          description: "One avatar with image or initials",
          fields: [:image_src, :initials, :alt, :size, :shape, :classes, :slots],
          slots: ["image"]
        },
        %{
          id: "group",
          label: "Group",
          description: "Stacked avatar group",
          default_props: %{"variant" => "group", "count" => 3},
          fields: [:image_src, :alt, :size, :count, :classes],
          slots: []
        },
        %{
          id: "with_status",
          label: "With status",
          description: "Avatar with online/offline dot",
          default_props: %{"status" => "online"},
          fields: [:image_src, :initials, :alt, :size, :shape, :status, :classes, :slots],
          slots: ["image"]
        }
      ],
      examples: [
        %{variant: "single", props: %{"initials" => "MG"}},
        %{variant: "group", props: %{"count" => 4}},
        %{variant: "with_status", props: %{"initials" => "JS", "status" => "online"}}
      ],
      fields: %{
        image_src: Field.media("image_src", label: "Image", bindable: true),
        initials: Field.text("initials", label: "Initials fallback", bindable: true),
        alt: Field.text("alt", label: "Alt text", bindable: true),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"Extra small", "xs"},
              {"Small", "sm"},
              {"Medium", "md"},
              {"Large", "lg"},
              {"Extra large", "xl"}
            ]
          ),
        shape:
          Field.select("shape",
            label: "Shape",
            options: [{"Circle", "circle"}, {"Rounded", "rounded"}, {"Square", "square"}]
          ),
        status:
          Field.select("status",
            label: "Status dot",
            options: [
              {"None", ""},
              {"Online", "online"},
              {"Offline", "offline"},
              {"Away", "away"},
              {"Busy", "busy"}
            ]
          ),
        count: Field.number("count", label: "Group count", min: 2, max: 8),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
