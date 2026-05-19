defmodule MangoCMSWeb.Builder.Manifests.Alert do
  @moduledoc "Builder manifest for the alert feedback component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.FeedbackComponents

  @impl true
  def manifest do
    %{
      name: "alert",
      label: "Alert",
      group: "Feedback",
      icon: "hero-exclamation-triangle",
      renderer: {FeedbackComponents, :alert},
      default_variant: "info",
      accepted_children: ["button", "anchor", "paragraph"],
      default_props: %{
        "title" => "Notice",
        "message" => "Important information for the visitor.",
        "tone" => "info",
        "variant" => "solid",
        "size" => "md",
        "icon" => "hero-information-circle"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "content", label: "Content", accepts: ["paragraph", "heading", "list"]},
        %{id: "actions", label: "Actions", accepts: ["button", "anchor"], max_children: 2}
      ],
      variants: [
        %{
          id: "info",
          label: "Info",
          default_props: %{"tone" => "info"},
          fields: fields(),
          slots: ["content", "actions"]
        },
        %{
          id: "success",
          label: "Success",
          default_props: %{"tone" => "success"},
          fields: fields(),
          slots: ["content", "actions"]
        },
        %{
          id: "warning",
          label: "Warning",
          default_props: %{"tone" => "warning"},
          fields: fields(),
          slots: ["content", "actions"]
        },
        %{
          id: "error",
          label: "Error",
          default_props: %{"tone" => "error"},
          fields: fields(),
          slots: ["content", "actions"]
        }
      ],
      examples: [
        %{variant: "info", props: %{"title" => "Info", "message" => "Helpful context."}},
        %{
          variant: "success",
          props: %{"title" => "Saved", "message" => "Your changes are live."}
        },
        %{
          variant: "warning",
          props: %{"title" => "Check this", "message" => "Some fields need review."}
        },
        %{variant: "error", props: %{"title" => "Failed", "message" => "Something went wrong."}}
      ],
      fields: %{
        title: Field.text("title", label: "Title", bindable: true),
        message: Field.textarea("message", label: "Message", bindable: true),
        tone: tone_field(),
        variant: variant_field(),
        size: size_field(),
        icon: Field.icon("icon", label: "Icon"),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end

  defp fields, do: [:title, :message, :tone, :variant, :size, :icon, :classes, :slots]

  defp tone_field,
    do:
      Field.select("tone",
        label: "Tone",
        options: [
          {"Info", "info"},
          {"Success", "success"},
          {"Warning", "warning"},
          {"Error", "error"}
        ]
      )

  defp variant_field,
    do:
      Field.select("variant",
        label: "Variant",
        options: [{"Solid", "solid"}, {"Soft", "soft"}, {"Outline", "outline"}, {"Dash", "dash"}]
      )

  defp size_field,
    do:
      Field.select("size",
        label: "Size",
        options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
      )
end
