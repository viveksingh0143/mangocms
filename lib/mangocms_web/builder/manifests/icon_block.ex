defmodule MangoCMSWeb.Builder.Manifests.IconBlock do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.MediaComponents

  @impl true
  def manifest do
    %{
      name: "icon_block",
      label: "Icon",
      group: "Media",
      icon: "hero-star",
      renderer: {MediaComponents, :icon_block},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "icon" => "hero-star",
        "size" => "md",
        "color" => "default",
        "label" => "",
        "label_size" => "sm",
        "align" => "start"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Icon with optional label",
          default_props: %{},
          fields: [:icon, :size, :color, :label, :label_size, :align, :classes]
        }
      ],
      fields: %{
        icon: Field.icon("icon", label: "Icon", required: true),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"XS", "xs"},
              {"SM", "sm"},
              {"MD", "md"},
              {"LG", "lg"},
              {"XL", "xl"}
            ]
          ),
        color:
          Field.select("color",
            label: "Color",
            options: [
              {"Default", "default"},
              {"Primary", "primary"},
              {"Secondary", "secondary"},
              {"Accent", "accent"},
              {"Success", "success"},
              {"Warning", "warning"},
              {"Error", "error"}
            ]
          ),
        label: Field.text("label", label: "Label", bindable: true),
        label_size:
          Field.select("label_size",
            label: "Label size",
            options: [
              {"XS", "xs"},
              {"SM", "sm"},
              {"Default", "default"},
              {"LG", "lg"}
            ]
          ),
        align:
          Field.select("align",
            label: "Align",
            options: [
              {"Start", "start"},
              {"Center", "center"},
              {"End", "end"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
