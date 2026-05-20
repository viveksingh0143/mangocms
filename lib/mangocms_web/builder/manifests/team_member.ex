defmodule MangoCMSWeb.Builder.Manifests.TeamMember do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "team_member",
      label: "Team Member",
      group: "Content",
      icon: "hero-user-circle",
      renderer: {ContentComponents, :team_member},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "name" => "Jane Doe",
        "role" => "Head of Design",
        "bio" => "Jane has 10+ years of experience leading design teams at top tech companies.",
        "photo" => "",
        "socials" => []
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Centered team member card",
          default_props: %{},
          fields: [:name, :role, :bio, :photo, :socials, :classes]
        }
      ],
      fields: %{
        name: Field.text("name", label: "Name", bindable: true, required: true),
        role: Field.text("role", label: "Role / Title", bindable: true),
        bio: Field.textarea("bio", label: "Bio", bindable: true),
        photo: Field.media("photo", label: "Photo"),
        socials: Field.action_list("socials", label: "Social links"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
