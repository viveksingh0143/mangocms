defmodule MangoCMSWeb.Builder.Manifests.TeamGrid do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "team_grid",
      label: "Team Grid",
      group: "Content",
      icon: "hero-user-group",
      renderer: {ContentComponents, :team_grid},
      default_variant: "grid_3",
      accepted_children: [],
      default_props: %{
        "members" => [
          %{"name" => "Alice Smith", "role" => "CEO", "photo" => ""},
          %{"name" => "Bob Jones", "role" => "CTO", "photo" => ""},
          %{"name" => "Carol Lee", "role" => "Designer", "photo" => ""}
        ],
        "columns" => "3"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "grid_2",
          label: "2 Cols",
          description: "Two-column team grid",
          default_props: %{"columns" => "2"},
          fields: [:members, :columns, :classes]
        },
        %{
          id: "grid_3",
          label: "3 Cols",
          description: "Three-column team grid",
          default_props: %{"columns" => "3"},
          fields: [:members, :columns, :classes]
        },
        %{
          id: "grid_4",
          label: "4 Cols",
          description: "Four-column team grid",
          default_props: %{"columns" => "4"},
          fields: [:members, :columns, :classes]
        }
      ],
      fields: %{
        members: Field.action_list("members", label: "Team members"),
        columns:
          Field.select("columns",
            label: "Columns",
            options: [
              {"2", "2"},
              {"3", "3"},
              {"4", "4"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
