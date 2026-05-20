defmodule MangoCMSWeb.Builder.Manifests.BackLink do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.UtilityComponents

  @impl true
  def manifest do
    %{
      name: "back_link",
      label: "Back Link",
      group: "Interactive",
      icon: "hero-arrow-left",
      renderer: {UtilityComponents, :back_link},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "label" => "Back",
        "href" => "#"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Back navigation link",
          default_props: %{},
          fields: [:label, :href, :classes]
        }
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true, required: true),
        href: Field.link("href", label: "URL"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
