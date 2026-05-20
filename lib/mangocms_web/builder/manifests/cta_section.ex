defmodule MangoCMSWeb.Builder.Manifests.CtaSection do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "cta_section",
      label: "CTA Section",
      group: "Content",
      icon: "hero-megaphone",
      renderer: {ContentComponents, :cta_section},
      default_variant: "centered",
      accepted_children: [],
      default_props: %{
        "eyebrow" => "",
        "title" => "Ready to get started?",
        "body" => "Join thousands of teams using our platform to build faster.",
        "primary_label" => "Get started free",
        "primary_href" => "#",
        "secondary_label" => "Learn more",
        "secondary_href" => "#",
        "bg" => "base-200"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "centered",
          label: "Centered",
          description: "Center-aligned CTA",
          default_props: %{},
          fields: [
            :eyebrow,
            :title,
            :body,
            :primary_label,
            :primary_href,
            :secondary_label,
            :secondary_href,
            :bg,
            :classes
          ]
        },
        %{
          id: "primary",
          label: "Primary",
          description: "Primary brand background",
          default_props: %{"bg" => "primary"},
          fields: [
            :eyebrow,
            :title,
            :body,
            :primary_label,
            :primary_href,
            :secondary_label,
            :secondary_href,
            :bg,
            :classes
          ]
        },
        %{
          id: "gradient",
          label: "Gradient",
          description: "Gradient background",
          default_props: %{"bg" => "gradient"},
          fields: [
            :eyebrow,
            :title,
            :body,
            :primary_label,
            :primary_href,
            :secondary_label,
            :secondary_href,
            :bg,
            :classes
          ]
        }
      ],
      fields: %{
        eyebrow: Field.text("eyebrow", label: "Eyebrow text", bindable: true),
        title: Field.text("title", label: "Heading", bindable: true, required: true),
        body: Field.textarea("body", label: "Body text", bindable: true),
        primary_label: Field.text("primary_label", label: "Primary button label", bindable: true),
        primary_href: Field.link("primary_href", label: "Primary button URL"),
        secondary_label: Field.text("secondary_label", label: "Secondary button label"),
        secondary_href: Field.link("secondary_href", label: "Secondary button URL"),
        bg:
          Field.select("bg",
            label: "Background",
            options: [
              {"Base 200", "base-200"},
              {"Primary", "primary"},
              {"Neutral", "neutral"},
              {"Gradient", "gradient"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
