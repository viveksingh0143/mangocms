defmodule MangoCMSWeb.Builder.Manifests.Dropdown do
  @moduledoc "Builder manifest for the dropdown component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ActionComponents

  @impl true
  def manifest do
    %{
      name: "dropdown",
      label: "Dropdown",
      group: "Action",
      icon: "hero-chevron-down",
      renderer: {ActionComponents, :dropdown},
      default_variant: "menu",
      accepted_children: ["button", "anchor", "icon", "badge"],
      default_props: %{
        "label" => "Open menu",
        "align" => "end",
        "button_style" => "btn-ghost",
        "items" => [
          %{"label" => "Profile", "href" => "#profile"},
          %{"label" => "Settings", "href" => "#settings"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "dropdown", owns: ["open"]},
      slots: [
        %{
          id: "trigger",
          label: "Trigger",
          accepts: ["button", "avatar", "icon"],
          max_children: 1
        },
        %{id: "items", label: "Items", accepts: ["anchor", "button", "menu_item"]}
      ],
      variants: [
        %{
          id: "menu",
          label: "Menu",
          description: "Button-triggered menu",
          fields: [:label, :align, :button_style, :items, :classes, :slots],
          slots: ["trigger", "items"]
        },
        %{
          id: "plain",
          label: "Plain",
          description: "Minimal dropdown",
          default_props: %{"button_style" => "btn-link"},
          fields: [:label, :align, :button_style, :items, :classes, :slots],
          slots: ["trigger", "items"]
        }
      ],
      examples: [
        %{variant: "menu", props: %{"label" => "More actions"}},
        %{variant: "plain", props: %{"label" => "Account"}}
      ],
      fields: %{
        label: Field.text("label", label: "Trigger label", required: true),
        align:
          Field.select("align",
            label: "Alignment",
            options: [
              {"Start", "start"},
              {"End", "end"},
              {"Top", "top"},
              {"Left", "left"},
              {"Right", "right"}
            ]
          ),
        button_style:
          Field.select("button_style",
            label: "Button style",
            options: [{"Ghost", "btn-ghost"}, {"Primary", "btn-primary"}, {"Link", "btn-link"}]
          ),
        items: Field.action_list("items", label: "Menu items"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
