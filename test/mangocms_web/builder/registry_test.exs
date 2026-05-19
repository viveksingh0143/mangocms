defmodule MangoCMSWeb.Builder.RegistryTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MangoCMSWeb.Builder.Inspector
  alias MangoCMSWeb.Builder.Registry
  alias MangoCMSWeb.Builder.Renderer

  describe "registry lookup" do
    test "loads manifests from Elixir modules" do
      manifests = Registry.all()

      assert Enum.any?(manifests, &(&1.name == "button"))
      assert Enum.any?(manifests, &(&1.name == "card"))
      assert Enum.any?(manifests, &(&1.name == "hero"))
      assert Enum.any?(manifests, &(&1.name == "modal"))
      assert Enum.any?(manifests, &(&1.name == "dropdown"))
      assert Enum.any?(manifests, &(&1.name == "carousel"))
      assert Enum.any?(manifests, &(&1.name == "tabs"))
      assert Enum.any?(manifests, &(&1.name == "input"))

      assert Registry.get!("button").renderer ==
               {MangoCMSWeb.BuilderLibrary.ActionComponents, :button}
    end

    test "raises for unknown manifests" do
      assert_raise ArgumentError, ~r/unknown builder component manifest/, fn ->
        Registry.get!("missing")
      end
    end
  end

  describe "variant contract" do
    test "finds variants and extracts only exposed fields" do
      variant = Registry.variant("card", "plain")
      fields = Registry.fields_for_variant("card", "plain")

      assert variant.label == "Plain"
      assert Enum.map(fields, & &1.key) == ["title", "body", "style", "custom", "slots"]
      refute Enum.any?(fields, &(&1.key == "image_src"))
    end

    test "returns slots for the selected variant" do
      slots = Registry.slots_for_variant("hero", "centered")

      assert Enum.map(slots, & &1.id) == ["content", "actions"]
      assert Enum.any?(slots, &("button" in &1.accepts))
    end

    test "declares examples for each variant" do
      for manifest <- Registry.all() do
        variant_ids = manifest.variants |> Enum.map(& &1.id) |> Enum.sort()
        example_ids = manifest.examples |> Enum.map(& &1.variant) |> Enum.sort()

        assert example_ids == variant_ids
      end
    end

    test "declares Alpine metadata for interactive components" do
      for name <- ~w(dropdown modal carousel tabs) do
        assert Registry.get!(name).alpine.component
      end
    end
  end

  describe "default nodes" do
    test "creates a content-tree compatible node from defaults" do
      node = Registry.default_node("card", "image_bottom")

      assert node["type"] == "component"
      assert node["name"] == "card"
      assert node["variant"] == "image_bottom"
      assert node["props"]["image_position"] == "bottom"
      assert node["props"]["title"] == "Card title"
      assert node["classes"]["custom"] == ""
      assert Map.keys(node["slots"]) == ["actions", "body", "media"]
    end

    test "creates examples as renderable nodes" do
      examples = Registry.examples("input")

      assert Enum.map(examples, & &1["variant"]) == ["text", "email", "number"]
      assert Enum.all?(examples, &(&1["name"] == "input"))
    end
  end

  describe "generic inspector" do
    test "renders controls from manifest fields" do
      manifest = Registry.get!("button")
      node = Registry.default_node("button", "primary")

      html =
        render_component(&Inspector.fields/1,
          manifest: manifest,
          node: node,
          variant_id: "primary",
          id_prefix: "test-inspector"
        )

      assert html =~ "Button"
      assert html =~ "name=\"node[props][label]\""
      assert html =~ "name=\"node[props][href]\""
      assert html =~ "name=\"node[classes][custom]\""
      assert html =~ "Supports dynamic bindings."
    end

    test "renders slot controls from manifest slots" do
      manifest = Registry.get!("hero")
      node = Registry.default_node("hero", "centered")

      html =
        render_component(&Inspector.fields/1,
          manifest: manifest,
          node: node,
          variant_id: "centered",
          id_prefix: "hero-inspector"
        )

      assert html =~ "Slots"
      assert html =~ "Content"
      assert html =~ "Actions"
      refute html =~ "Media"
    end
  end

  describe "renderer" do
    test "renders every golden component in public and builder contexts" do
      for name <- ~w(button card hero modal dropdown carousel tabs input) do
        node = Registry.default_node(name)

        public_html = render_component(&Renderer.node/1, node: node, context: %{mode: :public})
        builder_html = render_component(&Renderer.node/1, node: node, context: %{mode: :builder})

        assert public_html != ""
        assert builder_html != ""
      end
    end

    test "renders selected component content" do
      button =
        "button"
        |> Registry.default_node("primary")
        |> put_in(["props", "label"], "Start now")

      input =
        "input"
        |> Registry.default_node("email")
        |> put_in(["props", "label"], "Email address")

      assert render_component(&Renderer.node/1, node: button) =~ "Start now"
      assert render_component(&Renderer.node/1, node: input) =~ "Email address"
    end
  end
end
