defmodule MangoCMSWeb.Builder.Manifests.ChatBubble do
  @moduledoc "Builder manifest for the chat bubble component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "chat_bubble",
      label: "Chat bubble",
      group: "Data display",
      icon: "hero-chat-bubble-left-right",
      renderer: {DisplayComponents, :chat_bubble},
      default_variant: "start",
      accepted_children: [],
      default_props: %{
        "message" => "Hello! How can I help you today?",
        "align" => "start",
        "tone" => "",
        "header" => "Support",
        "time" => "12:45",
        "footer" => "",
        "avatar_enabled" => false,
        "avatar_src" => "",
        "avatar_alt" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "content", label: "Content", accepts: ["paragraph", "image", "button"]}
      ],
      variants: [
        %{
          id: "start",
          label: "Start",
          description: "Left-aligned chat bubble",
          default_props: %{"align" => "start"},
          fields: [
            :message,
            :tone,
            :header,
            :time,
            :footer,
            :avatar_enabled,
            :avatar_src,
            :classes,
            :slots
          ],
          slots: ["content"]
        },
        %{
          id: "end",
          label: "End",
          description: "Right-aligned chat bubble",
          default_props: %{"align" => "end"},
          fields: [
            :message,
            :tone,
            :header,
            :time,
            :footer,
            :avatar_enabled,
            :avatar_src,
            :classes,
            :slots
          ],
          slots: ["content"]
        }
      ],
      examples: [
        %{
          variant: "start",
          props: %{"message" => "Hi there! How can I help?", "header" => "Support"}
        },
        %{
          variant: "end",
          props: %{
            "message" => "I need help with my order.",
            "header" => "You",
            "tone" => "primary"
          }
        }
      ],
      fields: %{
        message: Field.textarea("message", label: "Message", bindable: true, required: true),
        tone:
          Field.select("tone",
            label: "Tone",
            options: [
              {"Default", ""},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Neutral", "neutral"},
              {"Info", "info"},
              {"Success", "success"},
              {"Warning", "warning"},
              {"Error", "error"}
            ]
          ),
        header: Field.text("header", label: "Sender name", bindable: true),
        time: Field.text("time", label: "Time label", bindable: true),
        footer: Field.text("footer", label: "Footer note", bindable: true),
        avatar_enabled: Field.toggle("avatar_enabled", label: "Show avatar"),
        avatar_src: Field.media("avatar_src", label: "Avatar image", bindable: true),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
