defmodule MangoCMSWeb.Builder.Manifests.Tabs do
  @moduledoc "Builder manifest for the tabs component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "tabs",
      label: "Tabs",
      group: "Navigation",
      icon: "hero-queue-list",
      renderer: {DisplayComponents, :tabs},
      default_variant: "boxed",
      accepted_children: ["heading", "paragraph", "card", "image"],
      default_props: %{
        "style" => "tabs-boxed",
        "active_item" => "overview",
        "align" => "start",
        "responsive" => true,
        "tabs" => [
          %{
            "id" => "overview",
            "label" => "Overview",
            "href" => "#overview",
            "body" => "Overview content"
          },
          %{
            "id" => "details",
            "label" => "Details",
            "href" => "#details",
            "body" => "Details content"
          }
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "tabs", owns: ["active"]},
      slots: [
        %{id: "panels", label: "Panels", accepts: ["section", "card", "paragraph", "image"]}
      ],
      variants: [
        %{
          id: "boxed",
          label: "Boxed",
          description: "Boxed tab navigation",
          default_props: %{"style" => "tabs-boxed"},
          fields: [:tabs, :active_item, :style, :align, :responsive, :classes, :slots],
          slots: ["panels"]
        },
        %{
          id: "lifted",
          label: "Lifted",
          description: "Lifted tab navigation",
          default_props: %{"style" => "tabs-lifted"},
          fields: [:tabs, :active_item, :style, :align, :responsive, :classes, :slots],
          slots: ["panels"]
        },
        %{
          id: "bordered",
          label: "Bordered",
          description: "Bordered navigation tabs",
          default_props: %{"style" => "tabs-border"},
          fields: [:tabs, :active_item, :style, :align, :responsive, :classes, :slots],
          slots: ["panels"]
        }
      ],
      examples: [
        %{variant: "boxed", props: %{"style" => "tabs-boxed"}},
        %{variant: "lifted", props: %{"style" => "tabs-lifted"}},
        %{variant: "bordered", props: %{"style" => "tabs-border", "active_item" => "details"}}
      ],
      fields: %{
        style:
          Field.select("style",
            label: "Style",
            options: [
              {"Boxed", "tabs-boxed"},
              {"Lifted", "tabs-lifted"},
              {"Bordered", "tabs-border"}
            ]
          ),
        tabs: Field.action_list("tabs", label: "Tabs"),
        active_item: Field.text("active_item", label: "Active tab ID"),
        align:
          Field.select("align",
            label: "Alignment",
            options: [{"Start", "start"}, {"Center", "center"}, {"End", "end"}]
          ),
        responsive: Field.toggle("responsive", label: "Stack on mobile"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
