defmodule MangoCMSWeb.Builder.Manifests.CodeBlock do
  @behaviour MangoCMSWeb.Builder.Manifest
  alias MangoCMSWeb.Builder.Field
  alias MangoCMSWeb.BuilderLibrary.TypographyComponents

  @impl true
  def manifest do
    %{
      name: "code_block",
      label: "Code Block",
      group: "Typography",
      icon: "hero-code-bracket",
      renderer: {TypographyComponents, :code_block},
      default_variant: "default",
      accepted_children: [],
      default_props: %{
        "code" => "// Your code here\nconst hello = \"world\";",
        "language" => "javascript"
      },
      default_classes: %{"custom" => ""},
      alpine: %{},
      slots: [],
      variants: [
        %{
          id: "default",
          label: "Default",
          description: "Syntax-highlighted code",
          default_props: %{},
          fields: [:code, :language, :classes]
        }
      ],
      fields: %{
        code: Field.textarea("code", label: "Code", required: true),
        language:
          Field.select("language",
            label: "Language",
            options: [
              {"Plain", ""},
              {"JavaScript", "javascript"},
              {"TypeScript", "typescript"},
              {"Elixir", "elixir"},
              {"HTML", "html"},
              {"CSS", "css"},
              {"Python", "python"},
              {"Ruby", "ruby"},
              {"Bash", "bash"},
              {"JSON", "json"},
              {"SQL", "sql"}
            ]
          ),
        classes: Field.class_list("custom", label: "Custom classes")
      }
    }
  end
end
