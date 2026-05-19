defmodule MangoCMSWeb.Builder.Manifests.Skeleton do
  @moduledoc "Builder manifest for skeleton placeholders."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.FeedbackComponents

  @impl true
  def manifest do
    %{
      name: "skeleton",
      label: "Skeleton",
      group: "Feedback",
      icon: "hero-rectangle-group",
      renderer: {FeedbackComponents, :skeleton},
      default_variant: "text",
      accepted_children: [],
      default_props: %{"rows" => 3, "shape" => "line", "size" => "md", "width" => "full"},
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "text",
          label: "Text",
          default_props: %{"shape" => "line", "rows" => 3},
          fields: fields()
        },
        %{
          id: "card",
          label: "Card",
          default_props: %{"shape" => "line", "rows" => 5, "size" => "lg"},
          fields: fields()
        },
        %{
          id: "avatar",
          label: "Avatar",
          default_props: %{"shape" => "circle", "rows" => 1},
          fields: fields()
        }
      ],
      examples: [
        %{variant: "text", props: %{"rows" => 3}},
        %{variant: "card", props: %{"rows" => 5, "size" => "lg"}},
        %{variant: "avatar", props: %{"shape" => "circle", "rows" => 1}}
      ],
      fields: %{
        rows: Field.number("rows", label: "Rows", min: 1, max: 12),
        shape:
          Field.select("shape", label: "Shape", options: [{"Line", "line"}, {"Circle", "circle"}]),
        size:
          Field.select("size",
            label: "Size",
            options: [{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]
          ),
        width:
          Field.select("width",
            label: "Width",
            options: [{"Full", "full"}, {"Narrow", "narrow"}, {"Wide", "wide"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end

  defp fields, do: [:rows, :shape, :size, :width, :classes]
end
