defmodule MangoCMSWeb.Builder.Manifests.Modal do
  @moduledoc "Builder manifest for the modal component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ActionComponents

  @impl true
  def manifest do
    %{
      name: "modal",
      label: "Modal",
      group: "Action",
      icon: "hero-window",
      renderer: {ActionComponents, :modal},
      default_variant: "standard",
      accepted_children: ["heading", "paragraph", "button", "anchor", "image"],
      default_props: %{
        "trigger_label" => "Open modal",
        "trigger_style" => "btn-primary",
        "title" => "Modal title",
        "body" => "Modal content",
        "close_label" => "Close",
        "size" => "md"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "modal", owns: ["open"]},
      slots: [
        %{id: "header", label: "Header", accepts: ["heading", "badge"], max_children: 2},
        %{id: "body", label: "Body", accepts: ["paragraph", "image", "list"]},
        %{id: "actions", label: "Actions", accepts: ["button", "anchor"], max_children: 3}
      ],
      variants: [
        %{
          id: "standard",
          label: "Standard",
          description: "Default centered modal",
          fields: [:trigger_label, :title, :body, :size, :trigger_style, :classes, :slots],
          slots: ["header", "body", "actions"]
        },
        %{
          id: "wide",
          label: "Wide",
          description: "Large content modal",
          default_props: %{"size" => "lg"},
          fields: [:trigger_label, :title, :body, :size, :trigger_style, :classes, :slots],
          slots: ["header", "body", "actions"]
        }
      ],
      examples: [
        %{variant: "standard", props: %{"trigger_label" => "Open details", "title" => "Details"}},
        %{
          variant: "wide",
          props: %{"trigger_label" => "Open preview", "title" => "Large preview"}
        }
      ],
      fields: %{
        trigger_label: Field.text("trigger_label", label: "Trigger label", required: true),
        trigger_style:
          Field.select("trigger_style",
            label: "Trigger style",
            options: [
              {"Primary", "btn-primary"},
              {"Secondary", "btn-secondary"},
              {"Ghost", "btn-ghost"}
            ]
          ),
        title: Field.text("title", label: "Title", bindable: true),
        body: Field.textarea("body", label: "Body", bindable: true),
        close_label: Field.text("close_label", label: "Close label"),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Medium", "md"}, {"Small", "sm"}, {"Large", "lg"}, {"Extra large", "xl"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
