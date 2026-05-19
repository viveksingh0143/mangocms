defmodule MangoCMSWeb.Builder.Manifests.List do
  @moduledoc "Builder manifest for collection-friendly lists."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "list",
      label: "List",
      group: "Data display",
      icon: "hero-list-bullet",
      renderer: {DisplayComponents, :list},
      default_variant: "simple",
      accepted_children: ["card", "image", "button", "link", "badge"],
      default_props: %{
        "collection" => "",
        "title_template" => "{{item.title}}",
        "meta_template" => "{{item.category}}",
        "body_template" => "{{item.excerpt}}",
        "density" => "normal"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "items", label: "Items", accepts: ["card", "image", "button", "link", "badge"]}
      ],
      variants: [
        %{
          id: "simple",
          label: "Simple",
          description: "Rows with title and description",
          fields: [
            :collection,
            :title_template,
            :meta_template,
            :body_template,
            :density,
            :classes,
            :slots
          ],
          slots: ["items"]
        },
        %{
          id: "compact",
          label: "Compact",
          description: "Tighter rows for dense data",
          default_props: %{"density" => "compact"},
          fields: [
            :collection,
            :title_template,
            :meta_template,
            :body_template,
            :density,
            :classes,
            :slots
          ],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "simple", props: %{}},
        %{variant: "compact", props: %{"density" => "compact"}}
      ],
      fields: %{
        collection: Field.text("collection", label: "Collection key", bindable: true),
        title_template: Field.text("title_template", label: "Title template", bindable: true),
        meta_template: Field.text("meta_template", label: "Meta template", bindable: true),
        body_template: Field.textarea("body_template", label: "Body template", bindable: true),
        density:
          Field.select("density",
            label: "Density",
            options: [{"Compact", "compact"}, {"Normal", "normal"}, {"Relaxed", "relaxed"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
