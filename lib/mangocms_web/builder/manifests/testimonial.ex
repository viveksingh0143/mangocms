defmodule MangoCMSWeb.Builder.Manifests.Testimonial do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "testimonial",
      label: "Testimonial",
      group: "Content",
      icon: "hero-chat-bubble-left-right",
      renderer: {ContentComponents, :testimonial},
      default_variant: "card",
      accepted_children: [],
      default_props: %{
        "quote" => "This product completely transformed how our team works. Highly recommended!",
        "name" => "Jane Doe",
        "role" => "CEO at Acme Corp",
        "avatar" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "card",
          label: "Card",
          description: "Bordered card testimonial",
          default_props: %{},
          fields: [:quote, :name, :role, :avatar, :classes]
        },
        %{
          id: "minimal",
          label: "Minimal",
          description: "Simple borderless quote",
          default_props: %{},
          fields: [:quote, :name, :role, :avatar, :classes]
        },
        %{
          id: "large",
          label: "Large",
          description: "Large featured quote",
          default_props: %{},
          fields: [:quote, :name, :role, :avatar, :classes]
        }
      ],
      fields: %{
        quote: Field.textarea("quote", label: "Quote", bindable: true, required: true),
        name: Field.text("name", label: "Name", bindable: true),
        role: Field.text("role", label: "Role / Company", bindable: true),
        avatar: Field.media("avatar", label: "Avatar image"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
