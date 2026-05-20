defmodule MangoCMSWeb.Builder.Manifests.PricingCard do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "pricing_card",
      label: "Pricing Card",
      group: "Content",
      icon: "hero-credit-card",
      renderer: {ContentComponents, :pricing_card},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "plan" => "Pro",
        "description" => "Everything you need to get started.",
        "price" => "$29",
        "period" => "mo",
        "features" => ["Feature one", "Feature two", "Feature three", "Priority support"],
        "cta_label" => "Get started",
        "cta_href" => "#",
        "highlighted" => false,
        "badge" => ""
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Standard pricing card",
          default_props: %{"highlighted" => false},
          fields: [
            :plan,
            :description,
            :price,
            :period,
            :features,
            :cta_label,
            :cta_href,
            :badge,
            :classes
          ]
        },
        %{
          id: "highlighted",
          label: "Highlighted",
          description: "Primary color featured card",
          default_props: %{"highlighted" => true},
          fields: [
            :plan,
            :description,
            :price,
            :period,
            :features,
            :cta_label,
            :cta_href,
            :badge,
            :classes
          ]
        }
      ],
      fields: %{
        plan: Field.text("plan", label: "Plan name", bindable: true, required: true),
        description: Field.text("description", label: "Description", bindable: true),
        price: Field.text("price", label: "Price", bindable: true),
        period: Field.text("period", label: "Period (e.g. mo, yr)"),
        features: Field.action_list("features", label: "Features"),
        cta_label: Field.text("cta_label", label: "Button label"),
        cta_href: Field.link("cta_href", label: "Button URL"),
        highlighted: Field.toggle("highlighted", label: "Highlighted"),
        badge: Field.text("badge", label: "Badge (e.g. Popular)"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
