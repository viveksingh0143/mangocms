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
        "tabs" => [
          %{"label" => "Overview", "body" => "Overview content"},
          %{"label" => "Details", "body" => "Details content"}
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
          fields: [:style, :tabs, :classes, :slots],
          slots: ["panels"]
        },
        %{
          id: "lifted",
          label: "Lifted",
          description: "Lifted tab navigation",
          default_props: %{"style" => "tabs-lifted"},
          fields: [:style, :tabs, :classes, :slots],
          slots: ["panels"]
        }
      ],
      examples: [
        %{variant: "boxed", props: %{"style" => "tabs-boxed"}},
        %{variant: "lifted", props: %{"style" => "tabs-lifted"}}
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
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
