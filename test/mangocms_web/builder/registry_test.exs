defmodule MangoCMSWeb.Builder.RegistryTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MangoCMSWeb.Builder.Inspector
  alias MangoCMSWeb.Builder.Registry

  describe "registry lookup" do
    test "loads manifests from Elixir modules" do
      manifests = Registry.all()

      assert Enum.any?(manifests, &(&1.name == "button"))
      assert Enum.any?(manifests, &(&1.name == "card"))
      assert Enum.any?(manifests, &(&1.name == "hero"))

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
  end
end
