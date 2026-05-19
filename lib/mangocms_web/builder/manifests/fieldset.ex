defmodule MangoCMSWeb.Builder.Manifests.Fieldset do
  @moduledoc "Builder manifest for the fieldset group component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "fieldset",
      label: "Fieldset",
      group: "Data input",
      icon: "hero-rectangle-group",
      renderer: {InputComponents, :fieldset},
      default_variant: "default",
      accepted_children: ["input", "textarea", "select", "checkbox", "radio", "toggle", "range"],
      default_props: %{
        "legend" => "Personal details",
        "help" => "",
        "disabled" => false,
        "style" => "default"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [
        %{
          id: "fields",
          label: "Fields",
          accepts: [
            "input",
            "textarea",
            "select",
            "checkbox",
            "radio",
            "toggle",
            "range",
            "rating"
          ]
        }
      ],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Fieldset with legend and no border",
          default_props: %{"style" => "default"},
          fields: [:legend, :help, :disabled, :classes, :slots]
        },
        %{
          id: "bordered",
          label: "Bordered",
          description: "Fieldset with a visible border frame",
          default_props: %{"style" => "bordered"},
          fields: [:legend, :help, :disabled, :classes, :slots]
        }
      ],
      examples: [
        %{
          variant: "default",
          props: %{"legend" => "Personal details", "style" => "default"}
        },
        %{
          variant: "bordered",
          props: %{"legend" => "Billing address", "style" => "bordered"}
        }
      ],
      fields: %{
        legend: Field.text("legend", label: "Legend / title", bindable: true),
        help: Field.text("help", label: "Help text", bindable: true),
        disabled: Field.toggle("disabled", label: "Disabled"),
        style:
          Field.select("style",
            label: "Style",
            options: [{"Default", "default"}, {"Bordered", "bordered"}]
          ),
        classes: Field.class_list("custom", label: "Custom classes"),
        slots: Field.slot_controls("slots", label: "Slots")
      }
    }
  end
end
