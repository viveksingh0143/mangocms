defmodule MangoCMSWeb.Builder.Manifests.PricingTable do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "pricing_table",
      label: "Pricing Table",
      group: "Content",
      icon: "hero-table-cells",
      renderer: {ContentComponents, :pricing_table},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "tiers" => [
          %{
            "plan" => "Starter",
            "price" => "$9",
            "period" => "mo",
            "cta_label" => "Start free",
            "cta_href" => "#",
            "features" => ["5 projects", "10 GB storage"]
          },
          %{
            "plan" => "Pro",
            "price" => "$29",
            "period" => "mo",
            "cta_label" => "Get Pro",
            "cta_href" => "#",
            "highlighted" => true,
            "badge" => "Popular",
            "features" => ["Unlimited projects", "100 GB storage", "Priority support"]
          },
          %{
            "plan" => "Enterprise",
            "price" => "$99",
            "period" => "mo",
            "cta_label" => "Contact us",
            "cta_href" => "#",
            "features" => ["Everything in Pro", "Dedicated support", "Custom integrations"]
          }
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Side-by-side pricing tiers",
          default_props: %{},
          fields: [:tiers, :classes]
        }
      ],
      fields: %{
        tiers: Field.action_list("tiers", label: "Pricing tiers"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
