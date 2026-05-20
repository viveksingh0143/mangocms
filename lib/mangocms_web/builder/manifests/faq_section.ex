defmodule MangoCMSWeb.Builder.Manifests.FaqSection do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.ContentComponents

  @impl true
  def manifest do
    %{
      name: "faq_section",
      label: "FAQ Section",
      group: "Content",
      icon: "hero-question-mark-circle",
      renderer: {ContentComponents, :faq_section},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "items" => [
          %{
            "question" => "What is your refund policy?",
            "answer" => "We offer a 30-day money-back guarantee on all plans."
          },
          %{
            "question" => "Do you offer support?",
            "answer" => "Yes, we provide 24/7 support via chat and email."
          },
          %{
            "question" => "Can I cancel anytime?",
            "answer" =>
              "Absolutely. Cancel your subscription at any time with no questions asked."
          }
        ]
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "faq", owns: ["open"]},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Accordion FAQ",
          default_props: %{},
          fields: [:items, :classes]
        }
      ],
      fields: %{
        items: Field.action_list("items", label: "FAQ items"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
