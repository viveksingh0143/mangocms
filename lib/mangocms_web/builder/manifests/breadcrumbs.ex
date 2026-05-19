defmodule MangoCMSWeb.Builder.Manifests.Breadcrumbs do
  @moduledoc "Builder manifest for breadcrumbs navigation."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.NavigationComponents

  @impl true
  def manifest do
    %{
      name: "breadcrumbs",
      label: "Breadcrumbs",
      group: "Navigation",
      icon: "hero-chevron-right",
      renderer: {NavigationComponents, :breadcrumbs},
      default_variant: "simple",
      accepted_children: ["link", "icon"],
      default_props: %{
        "align" => "start",
        "items" => [
          %{"label" => "Home", "href" => "/"},
          %{"label" => "CMS", "href" => "/admin"},
          %{"label" => "Pages", "href" => "#"}
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "items", label: "Items", accepts: ["link", "icon"]}
      ],
      variants: [
        %{
          id: "simple",
          label: "Simple",
          description: "Compact breadcrumb trail",
          fields: [:items, :align, :classes, :slots],
          slots: ["items"]
        },
        %{
          id: "centered",
          label: "Centered",
          description: "Centered breadcrumb trail",
          default_props: %{"align" => "center"},
          fields: [:items, :align, :classes, :slots],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "simple", props: %{}},
        %{variant: "centered", props: %{"align" => "center"}}
      ],
      fields: %{
        items: Field.action_list("items", label: "Breadcrumb links"),
        align:
          Field.select("align",
            label: "Alignment",
            options: [{"Start", "start"}, {"Center", "center"}, {"End", "end"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
