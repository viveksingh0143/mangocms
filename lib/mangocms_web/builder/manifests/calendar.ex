defmodule MangoCMSWeb.Builder.Manifests.Calendar do
  @moduledoc "Builder manifest for the calendar / date-picker component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.InputComponents

  @impl true
  def manifest do
    %{
      name: "calendar",
      label: "Calendar",
      group: "Data input",
      icon: "hero-calendar-days",
      renderer: {InputComponents, :calendar},
      default_variant: "monthly",
      accepted_children: [],
      default_props: %{
        "label" => "",
        "field_name" => "date",
        "value" => "",
        "show_selected" => true
      },
      default_classes: %{"custom" => ""},
      alpine: %{
        component: "calendar",
        owns: ["selected", "year", "month", "today"]
      },
      slots: [],
      variants: [
        %{
          id: "monthly",
          label: "Monthly",
          description: "Full month calendar with navigation",
          default_props: %{"show_selected" => true},
          fields: [:label, :field_name, :show_selected, :classes]
        },
        %{
          id: "mini",
          label: "Mini",
          description: "Compact calendar without selected display",
          default_props: %{"show_selected" => false},
          fields: [:label, :field_name, :classes]
        }
      ],
      examples: [
        %{variant: "monthly", props: %{"label" => "Pick a date", "show_selected" => true}},
        %{variant: "mini", props: %{"label" => "", "show_selected" => false}}
      ],
      fields: %{
        label: Field.text("label", label: "Label", bindable: true),
        field_name: Field.text("field_name", label: "Field name", required: true),
        show_selected: Field.toggle("show_selected", label: "Show selected date text"),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
