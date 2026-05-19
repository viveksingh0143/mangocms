defmodule MangoCMSWeb.Builder.Manifests.Pagination do
  @moduledoc "Builder manifest for pagination navigation."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.NavigationComponents

  @impl true
  def manifest do
    %{
      name: "pagination",
      label: "Pagination",
      group: "Navigation",
      icon: "hero-ellipsis-horizontal",
      renderer: {NavigationComponents, :pagination},
      default_variant: "numbered",
      accepted_children: ["link", "button"],
      default_props: %{
        "current_page" => 2,
        "total_pages" => 5,
        "base_href" => "?page=",
        "previous_href" => "?page=1",
        "next_href" => "?page=3",
        "align" => "center"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{id: "items", label: "Items", accepts: ["link", "button"], max_children: 9}
      ],
      variants: [
        %{
          id: "numbered",
          label: "Numbered",
          description: "Page number buttons",
          fields: [
            :current_page,
            :total_pages,
            :base_href,
            :previous_href,
            :next_href,
            :align,
            :classes,
            :slots
          ],
          slots: ["items"]
        },
        %{
          id: "compact",
          label: "Compact",
          description: "Small pagination set",
          default_props: %{"total_pages" => 3},
          fields: [
            :current_page,
            :total_pages,
            :base_href,
            :previous_href,
            :next_href,
            :align,
            :classes,
            :slots
          ],
          slots: ["items"]
        }
      ],
      examples: [
        %{variant: "numbered", props: %{}},
        %{variant: "compact", props: %{"total_pages" => 3}}
      ],
      fields: %{
        current_page: Field.number("current_page", label: "Current page", min: 1, step: 1),
        total_pages: Field.number("total_pages", label: "Total pages", min: 1, step: 1),
        base_href: Field.link("base_href", label: "Base link"),
        previous_href: Field.link("previous_href", label: "Previous link"),
        next_href: Field.link("next_href", label: "Next link"),
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
