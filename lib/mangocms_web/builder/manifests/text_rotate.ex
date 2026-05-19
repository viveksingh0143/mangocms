defmodule MangoCMSWeb.Builder.Manifests.TextRotate do
  @moduledoc "Builder manifest for the rotating text component."

  @behaviour MangoCMSWeb.Builder.Manifest

  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.DisplayComponents

  @impl true
  def manifest do
    %{
      name: "text_rotate",
      label: "Text rotate",
      group: "Data display",
      icon: "hero-arrow-path",
      renderer: {DisplayComponents, :text_rotate},
      default_variant: "inline",
      accepted_children: [],
      default_props: %{
        "words" => "fast,scalable,composable",
        "prefix" => "Build something",
        "suffix" => ".",
        "size" => "md",
        "interval_ms" => 2_000
      },
      default_classes: %{"custom" => ""},
      alpine: %{component: "text_rotate", owns: ["words", "idx"]},
      slots: [],
      variants: [
        %{
          id: "inline",
          label: "Inline",
          description: "Rotating word inline with prefix/suffix text",
          fields: [:words, :prefix, :suffix, :size, :interval_ms, :classes]
        },
        %{
          id: "standalone",
          label: "Standalone",
          description: "Rotating word only, no surrounding text",
          default_props: %{"prefix" => "", "suffix" => ""},
          fields: [:words, :size, :interval_ms, :classes]
        }
      ],
      examples: [
        %{
          variant: "inline",
          props: %{
            "prefix" => "MangoCMS is",
            "words" => "fast,flexible,powerful",
            "suffix" => "."
          }
        },
        %{variant: "standalone", props: %{"words" => "Publish,Manage,Grow", "size" => "lg"}}
      ],
      fields: %{
        words:
          Field.text("words",
            label: "Words (comma-separated)",
            placeholder: "fast,scalable,composable",
            bindable: true,
            required: true
          ),
        prefix: Field.text("prefix", label: "Prefix text", bindable: true),
        suffix: Field.text("suffix", label: "Suffix text", bindable: true),
        size:
          Field.select("size",
            label: "Size",
            options: [
              {"Small", "sm"},
              {"Medium", "md"},
              {"Large", "lg"},
              {"Extra large", "xl"}
            ]
          ),
        interval_ms:
          Field.number("interval_ms",
            label: "Interval (ms)",
            min: 500,
            max: 10_000,
            step: 100
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
