defmodule MangoCMSWeb.Builder.Manifests.CookieBanner do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.UtilityComponents

  @impl true
  def manifest do
    %{
      name: "cookie_banner",
      label: "Cookie Banner",
      group: "Interactive",
      icon: "hero-shield-check",
      renderer: {UtilityComponents, :cookie_banner},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "title" => "We use cookies",
        "body" =>
          "We use cookies to improve your experience. By continuing, you agree to our privacy policy.",
        "policy_label" => "Privacy Policy",
        "policy_href" => "#",
        "accept_label" => "Accept all",
        "decline_label" => "Decline"
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "cookie_banner", owns: ["accepted"]},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Cookie consent banner",
          default_props: %{},
          fields: [
            :title,
            :body,
            :policy_label,
            :policy_href,
            :accept_label,
            :decline_label,
            :classes
          ]
        }
      ],
      fields: %{
        title: Field.text("title", label: "Title", bindable: true, required: true),
        body: Field.textarea("body", label: "Description", bindable: true),
        policy_label: Field.text("policy_label", label: "Policy link label"),
        policy_href: Field.link("policy_href", label: "Policy URL"),
        accept_label: Field.text("accept_label", label: "Accept button label"),
        decline_label: Field.text("decline_label", label: "Decline button label"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
