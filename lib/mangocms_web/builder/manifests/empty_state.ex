defmodule MangoCMSWeb.Builder.Manifests.EmptyState do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "empty_state",
      label: "Empty State",
      group: "Content",
      icon: "hero-inbox",
      renderer: {ContentComponents, :empty_state},
      default_variant: "icon",
      accepted_children: [],
      default_props: %{
        "icon" => "hero-inbox",
        "image" => "",
        "title" => "Nothing here yet",
        "body" => "Get started by creating your first item.",
        "cta_label" => "Create new",
        "cta_href" => "#"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "icon",
          label: "Icon",
          description: "Icon-based empty state",
          default_props: %{"image" => ""},
          fields: [:icon, :title, :body, :cta_label, :cta_href, :classes]
        },
        %{
          id: "image",
          label: "Image",
          description: "Illustration empty state",
          default_props: %{},
          fields: [:image, :title, :body, :cta_label, :cta_href, :classes]
        }
      ],
      fields: %{
        icon: Field.icon("icon", label: "Icon"),
        image: Field.media("image", label: "Illustration image"),
        title: Field.text("title", label: "Title", bindable: true, required: true),
        body: Field.textarea("body", label: "Description", bindable: true),
        cta_label: Field.text("cta_label", label: "Button label"),
        cta_href: Field.link("cta_href", label: "Button URL"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
