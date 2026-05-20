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
      assert Enum.any?(manifests, &(&1.name == "accordion"))
      assert Enum.any?(manifests, &(&1.name == "card"))
      assert Enum.any?(manifests, &(&1.name == "hero"))
      assert Enum.any?(manifests, &(&1.name == "modal"))
      assert Enum.any?(manifests, &(&1.name == "dropdown"))
      assert Enum.any?(manifests, &(&1.name == "fab"))
      assert Enum.any?(manifests, &(&1.name == "swap"))
      assert Enum.any?(manifests, &(&1.name == "theme_controller"))
      assert Enum.any?(manifests, &(&1.name == "alert"))
      assert Enum.any?(manifests, &(&1.name == "loading"))
      assert Enum.any?(manifests, &(&1.name == "progress"))
      assert Enum.any?(manifests, &(&1.name == "radial_progress"))
      assert Enum.any?(manifests, &(&1.name == "skeleton"))
      assert Enum.any?(manifests, &(&1.name == "toast"))
      assert Enum.any?(manifests, &(&1.name == "tooltip"))
      assert Enum.any?(manifests, &(&1.name == "divider"))
      assert Enum.any?(manifests, &(&1.name == "drawer"))
      assert Enum.any?(manifests, &(&1.name == "footer"))
      assert Enum.any?(manifests, &(&1.name == "indicator"))
      assert Enum.any?(manifests, &(&1.name == "join"))
      assert Enum.any?(manifests, &(&1.name == "mask"))
      assert Enum.any?(manifests, &(&1.name == "stack"))
      assert Enum.any?(manifests, &(&1.name == "breadcrumbs"))
      assert Enum.any?(manifests, &(&1.name == "dock"))
      assert Enum.any?(manifests, &(&1.name == "link"))
      assert Enum.any?(manifests, &(&1.name == "menu"))
      assert Enum.any?(manifests, &(&1.name == "navbar"))
      assert Enum.any?(manifests, &(&1.name == "pagination"))
      assert Enum.any?(manifests, &(&1.name == "steps"))
      assert Enum.any?(manifests, &(&1.name == "carousel"))
      assert Enum.any?(manifests, &(&1.name == "collapse"))
      assert Enum.any?(manifests, &(&1.name == "list"))
      assert Enum.any?(manifests, &(&1.name == "stat"))
      assert Enum.any?(manifests, &(&1.name == "table"))
      assert Enum.any?(manifests, &(&1.name == "timeline"))
      assert Enum.any?(manifests, &(&1.name == "tabs"))
      assert Enum.any?(manifests, &(&1.name == "input"))
      assert Enum.any?(manifests, &(&1.name == "avatar"))
      assert Enum.any?(manifests, &(&1.name == "badge"))
      assert Enum.any?(manifests, &(&1.name == "chat_bubble"))
      assert Enum.any?(manifests, &(&1.name == "countdown"))
      assert Enum.any?(manifests, &(&1.name == "diff"))
      assert Enum.any?(manifests, &(&1.name == "hover_3d_card"))
      assert Enum.any?(manifests, &(&1.name == "hover_gallery"))
      assert Enum.any?(manifests, &(&1.name == "kbd"))
      assert Enum.any?(manifests, &(&1.name == "status"))
      assert Enum.any?(manifests, &(&1.name == "text_rotate"))
      assert Enum.any?(manifests, &(&1.name == "textarea"))
      assert Enum.any?(manifests, &(&1.name == "select"))
      assert Enum.any?(manifests, &(&1.name == "checkbox"))
      assert Enum.any?(manifests, &(&1.name == "radio"))
      assert Enum.any?(manifests, &(&1.name == "toggle"))
      assert Enum.any?(manifests, &(&1.name == "range"))
      assert Enum.any?(manifests, &(&1.name == "rating"))
      assert Enum.any?(manifests, &(&1.name == "calendar"))
      assert Enum.any?(manifests, &(&1.name == "fieldset"))
      assert Enum.any?(manifests, &(&1.name == "file_input"))
      assert Enum.any?(manifests, &(&1.name == "filter"))
      assert Enum.any?(manifests, &(&1.name == "label"))
      assert Enum.any?(manifests, &(&1.name == "validator"))
      assert Enum.any?(manifests, &(&1.name == "mockup_browser"))
      assert Enum.any?(manifests, &(&1.name == "mockup_code"))
      assert Enum.any?(manifests, &(&1.name == "mockup_phone"))
      assert Enum.any?(manifests, &(&1.name == "mockup_window"))

      assert Registry.get!("button").renderer ==
               {MangoCMSWeb.BuilderLibrary.ActionComponents, :button}

      # New component groups
      assert Enum.any?(manifests, &(&1.name == "heading"))
      assert Enum.any?(manifests, &(&1.name == "paragraph"))
      assert Enum.any?(manifests, &(&1.name == "image"))
      assert Enum.any?(manifests, &(&1.name == "section"))
      assert Enum.any?(manifests, &(&1.name == "container"))
      assert Enum.any?(manifests, &(&1.name == "feature_card"))
      assert Enum.any?(manifests, &(&1.name == "cta_section"))
      assert Enum.any?(manifests, &(&1.name == "copy_button"))
      assert Enum.any?(manifests, &(&1.name == "table_of_contents"))
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

      assert Enum.map(fields, & &1.key) == [
               "title",
               "eyebrow",
               "body",
               "meta",
               "collection",
               "style",
               "custom",
               "slots"
             ]

      refute Enum.any?(fields, &(&1.key == "image_src"))
    end

    test "returns slots for the selected variant" do
      slots = Registry.slots_for_variant("hero", "centered")

      assert Enum.map(slots, & &1.id) == ["content", "actions"]
      assert Enum.any?(slots, &("button" in &1.accepts))
    end

    test "declares examples for each variant (manifests that opt in)" do
      for manifest <- Registry.all(), manifest.examples != [] do
        variant_ids = manifest.variants |> Enum.map(& &1.id) |> Enum.sort()
        example_ids = manifest.examples |> Enum.map(& &1.variant) |> Enum.sort()

        assert example_ids == variant_ids,
               "#{manifest.name}: examples #{inspect(example_ids)} don't match variants #{inspect(variant_ids)}"
      end
    end

    test "declares Alpine metadata for interactive components" do
      for name <-
            ~w(dropdown modal fab swap theme_controller toast tooltip drawer hero menu navbar accordion collapse carousel tabs) do
        assert Registry.get!(name).alpine.component
      end
    end

    test "data display batch 2 manifests are in Data display group with variants" do
      for name <-
            ~w(avatar badge chat_bubble countdown diff hover_3d_card hover_gallery kbd status text_rotate) do
        manifest = Registry.get!(name)
        assert manifest.group == "Data display", "#{name} should be in Data display group"
        assert manifest.variants != [], "#{name} should have variants"
      end
    end

    test "declares Alpine metadata for batch 2 interactive components" do
      for name <- ~w(countdown hover_3d_card text_rotate) do
        assert Registry.get!(name).alpine.component,
               "#{name} should declare Alpine component metadata"
      end
    end

    test "data display manifests expose collection-friendly fields" do
      for name <- ~w(accordion card carousel collapse list stat table timeline) do
        manifest = Registry.get!(name)

        assert manifest.group == "Data display"
        assert manifest.variants != []
      end

      for name <- ~w(accordion card carousel list table timeline) do
        fields = Registry.fields_for_variant(name)
        assert Enum.any?(fields, & &1.bindable)
      end
    end

    test "layout manifests expose slots and accepted child types" do
      for name <- ~w(drawer footer hero indicator join mask stack) do
        manifest = Registry.get!(name)

        assert manifest.slots != []
        assert manifest.accepted_children != []
        assert Enum.all?(manifest.slots, &(&1.accepts != []))
      end

      assert Registry.get!("divider").slots == []
      assert Registry.get!("divider").accepted_children == []
    end

    test "navigation manifests expose slots and accepted child types" do
      for name <- ~w(breadcrumbs dock menu navbar pagination steps tabs) do
        manifest = Registry.get!(name)

        assert manifest.group == "Navigation"
        assert manifest.slots != []
        assert manifest.accepted_children != []
        assert Enum.all?(manifest.slots, &(&1.accepts != []))
      end

      assert Registry.get!("link").group == "Navigation"
      assert Registry.get!("link").slots == []
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
      for name <-
            ~w(button accordion card hero modal dropdown fab swap theme_controller carousel collapse list stat table timeline tabs input textarea select checkbox radio toggle range rating calendar fieldset file_input filter label validator alert loading progress radial_progress skeleton toast tooltip divider drawer footer indicator join mask stack breadcrumbs dock link menu navbar pagination steps avatar badge chat_bubble countdown diff hover_3d_card hover_gallery kbd status text_rotate mockup_browser mockup_code mockup_phone mockup_window) do
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

    test "renders action component Alpine hooks and default content" do
      for name <- ~w(dropdown modal fab swap theme_controller) do
        html = render_component(&Renderer.node/1, node: Registry.default_node(name))

        assert html =~ "x-data"
      end

      assert render_component(&Renderer.node/1, node: Registry.default_node("fab", "speed_dial")) =~
               "New page"

      assert render_component(&Renderer.node/1, node: Registry.default_node("theme_controller")) =~
               "Cupcake"
    end

    test "renders feedback component defaults and Alpine behavior" do
      assert render_component(&Renderer.node/1, node: Registry.default_node("alert", "success")) =~
               "alert-success"

      assert render_component(&Renderer.node/1, node: Registry.default_node("loading", "dots")) =~
               "loading-dots"

      assert render_component(&Renderer.node/1,
               node: Registry.default_node("progress", "warning")
             ) =~
               "progress-warning"

      assert render_component(&Renderer.node/1, node: Registry.default_node("radial_progress")) =~
               "radial-progress"

      assert render_component(&Renderer.node/1, node: Registry.default_node("skeleton", "avatar")) =~
               "skeleton"

      toast_html =
        render_component(&Renderer.node/1, node: Registry.default_node("toast", "success"))

      tooltip_html =
        render_component(&Renderer.node/1, node: Registry.default_node("tooltip", "top"))

      assert toast_html =~ "x-data"
      assert toast_html =~ "toast"
      assert tooltip_html =~ "x-data"
      assert tooltip_html =~ "data-tip"
    end

    test "renders layout component defaults and Alpine behavior" do
      assert render_component(&Renderer.node/1, node: Registry.default_node("divider", "labeled")) =~
               "divider"

      drawer_html =
        render_component(&Renderer.node/1, node: Registry.default_node("drawer", "right"))

      hero_html =
        render_component(&Renderer.node/1, node: Registry.default_node("hero", "fullscreen"))

      assert drawer_html =~ "drawer"
      assert drawer_html =~ "drawer-end"
      assert drawer_html =~ "x-data"
      assert hero_html =~ "min-h-screen"
      assert hero_html =~ "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("footer", "minimal")) =~
               "footer"

      assert render_component(&Renderer.node/1, node: Registry.default_node("indicator")) =~
               "indicator"

      assert render_component(&Renderer.node/1, node: Registry.default_node("join", "vertical")) =~
               "join-vertical"

      assert render_component(&Renderer.node/1, node: Registry.default_node("mask", "hexagon")) =~
               "mask-hexagon"

      assert render_component(&Renderer.node/1, node: Registry.default_node("stack")) =~
               "stack"
    end

    test "renders navigation component defaults and Alpine behavior" do
      assert render_component(&Renderer.node/1, node: Registry.default_node("breadcrumbs")) =~
               "breadcrumbs"

      assert render_component(&Renderer.node/1, node: Registry.default_node("dock")) =~
               "dock-active"

      assert render_component(&Renderer.node/1, node: Registry.default_node("link", "button")) =~
               "btn-primary"

      menu_html =
        render_component(&Renderer.node/1, node: Registry.default_node("menu", "horizontal"))

      navbar_html = render_component(&Renderer.node/1, node: Registry.default_node("navbar"))

      tabs_html =
        render_component(&Renderer.node/1, node: Registry.default_node("tabs", "bordered"))

      assert menu_html =~ "menu-horizontal"
      assert menu_html =~ "x-data"
      assert navbar_html =~ "navbar"
      assert navbar_html =~ "x-data"
      assert tabs_html =~ "tabs-border"
      assert tabs_html =~ "active"

      assert render_component(&Renderer.node/1, node: Registry.default_node("pagination")) =~
               "btn-active"

      assert render_component(&Renderer.node/1, node: Registry.default_node("steps", "vertical")) =~
               "steps-vertical"
    end

    test "renders data display batch 2 defaults and Alpine behavior" do
      assert render_component(&Renderer.node/1, node: Registry.default_node("avatar")) =~
               "avatar"

      assert render_component(&Renderer.node/1, node: Registry.default_node("avatar", "group")) =~
               "avatar-group"

      assert render_component(&Renderer.node/1, node: Registry.default_node("badge")) =~
               "badge"

      assert render_component(&Renderer.node/1, node: Registry.default_node("badge", "outline")) =~
               "badge-outline"

      assert render_component(&Renderer.node/1, node: Registry.default_node("chat_bubble")) =~
               "chat-bubble"

      assert render_component(&Renderer.node/1, node: Registry.default_node("chat_bubble", "end")) =~
               "chat-end"

      countdown_html =
        render_component(&Renderer.node/1, node: Registry.default_node("countdown", "full"))

      assert countdown_html =~ "countdown"
      assert countdown_html =~ "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("diff", "text")) =~
               "diff"

      hover_html =
        render_component(&Renderer.node/1, node: Registry.default_node("hover_3d_card"))

      assert hover_html =~ "perspective"
      assert hover_html =~ "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("hover_gallery")) =~
               "grid-cols-3"

      assert render_component(&Renderer.node/1,
               node: Registry.default_node("hover_gallery", "grid_4")
             ) =~
               "grid-cols-4"

      assert render_component(&Renderer.node/1, node: Registry.default_node("kbd")) =~
               "kbd"

      assert render_component(&Renderer.node/1, node: Registry.default_node("status")) =~
               "status"

      text_rotate_html =
        render_component(&Renderer.node/1, node: Registry.default_node("text_rotate"))

      assert text_rotate_html =~ "x-data"
      assert text_rotate_html =~ "words"
    end

    test "renders data input batch 1 components" do
      assert render_component(&Renderer.node/1, node: Registry.default_node("textarea")) =~
               "textarea"

      assert render_component(&Renderer.node/1, node: Registry.default_node("textarea", "ghost")) =~
               "textarea-ghost"

      assert render_component(&Renderer.node/1, node: Registry.default_node("select")) =~
               "select"

      assert render_component(&Renderer.node/1, node: Registry.default_node("select", "multiple")) =~
               "multiple"

      assert render_component(&Renderer.node/1, node: Registry.default_node("checkbox")) =~
               "checkbox"

      assert render_component(&Renderer.node/1, node: Registry.default_node("checkbox", "group")) =~
               "Option"

      assert render_component(&Renderer.node/1, node: Registry.default_node("radio")) =~
               "radio"

      assert render_component(&Renderer.node/1,
               node: Registry.default_node("radio", "horizontal")
             ) =~
               "flex-row"

      assert render_component(&Renderer.node/1, node: Registry.default_node("toggle")) =~
               "toggle"

      assert render_component(&Renderer.node/1,
               node: Registry.default_node("toggle", "label_right")
             ) =~
               "toggle"

      assert render_component(&Renderer.node/1, node: Registry.default_node("range")) =~
               "range"

      assert render_component(&Renderer.node/1, node: Registry.default_node("range", "stepped")) =~
               "range"

      assert render_component(&Renderer.node/1, node: Registry.default_node("rating")) =~
               "mask-star-2"

      assert render_component(&Renderer.node/1, node: Registry.default_node("rating", "hearts")) =~
               "mask-heart"
    end

    test "data input batch 1 manifests are in Data input group with variants" do
      for name <- ~w(textarea select checkbox radio toggle range rating) do
        manifest = Registry.get!(name)
        assert manifest.group == "Data input", "#{name} should be in Data input group"
        assert manifest.variants != [], "#{name} should have variants"
        assert manifest.alpine == %{}, "#{name} should have empty alpine (no JS needed)"
      end
    end

    test "renders data input batch 2 components" do
      calendar_html =
        render_component(&Renderer.node/1, node: Registry.default_node("calendar", "monthly"))

      assert calendar_html =~ "x-data"
      assert calendar_html =~ "monthLabel"
      assert calendar_html =~ "grid-cols-7"

      assert render_component(&Renderer.node/1, node: Registry.default_node("calendar", "mini")) =~
               "x-data"

      fieldset_html =
        render_component(&Renderer.node/1, node: Registry.default_node("fieldset", "default"))

      assert fieldset_html =~ "fieldset"
      assert fieldset_html =~ "Personal details"

      assert render_component(&Renderer.node/1,
               node: Registry.default_node("fieldset", "bordered")
             ) =~
               "border"

      assert render_component(&Renderer.node/1, node: Registry.default_node("file_input")) =~
               "file-input"

      assert render_component(&Renderer.node/1,
               node: Registry.default_node("file_input", "image")
             ) =~
               "image/*"

      filter_html =
        render_component(&Renderer.node/1, node: Registry.default_node("filter", "default"))

      assert filter_html =~ "filter"
      assert filter_html =~ "x-data"
      assert filter_html =~ "filter-reset"

      assert render_component(&Renderer.node/1, node: Registry.default_node("filter", "primary")) =~
               "btn-primary"

      assert render_component(&Renderer.node/1, node: Registry.default_node("label", "default")) =~
               "label-text"

      assert render_component(&Renderer.node/1, node: Registry.default_node("label", "with_alt")) =~
               "label-text-alt"

      validator_html =
        render_component(&Renderer.node/1, node: Registry.default_node("validator", "required"))

      assert validator_html =~ "validator"
      assert validator_html =~ "required"

      assert render_component(&Renderer.node/1,
               node: Registry.default_node("validator", "pattern")
             ) =~
               "pattern"
    end

    test "data input batch 2 manifests are in Data input group with variants" do
      for name <- ~w(calendar fieldset file_input filter label validator) do
        manifest = Registry.get!(name)
        assert manifest.group == "Data input", "#{name} should be in Data input group"
        assert manifest.variants != [], "#{name} should have variants"
      end

      assert Registry.get!("calendar").alpine.component == "calendar"
      assert Registry.get!("filter").alpine.component == "filter"
      assert Registry.get!("fieldset").slots != []
      assert Registry.get!("fieldset").accepted_children != []
    end

    test "renders mockup components in both themes" do
      browser_light =
        render_component(&Renderer.node/1,
          node: Registry.default_node("mockup_browser", "default")
        )

      browser_dark =
        render_component(&Renderer.node/1, node: Registry.default_node("mockup_browser", "dark"))

      assert browser_light =~ "mockup-browser"
      assert browser_light =~ "mockup-browser-toolbar"
      assert browser_light =~ "https://example.com"
      assert browser_dark =~ "mockup-browser"

      code_terminal =
        render_component(&Renderer.node/1, node: Registry.default_node("mockup_code", "terminal"))

      code_light =
        render_component(&Renderer.node/1, node: Registry.default_node("mockup_code", "light"))

      assert code_terminal =~ "mockup-code"
      assert code_terminal =~ "bg-neutral"
      assert code_terminal =~ "mix phx.server"
      assert code_terminal =~ "text-success"
      assert code_light =~ "mockup-code"
      assert code_light =~ "npm install"

      phone_default =
        render_component(&Renderer.node/1, node: Registry.default_node("mockup_phone", "default"))

      phone_large =
        render_component(&Renderer.node/1, node: Registry.default_node("mockup_phone", "large"))

      assert phone_default =~ "mockup-phone"
      assert phone_default =~ "phone-1"
      assert phone_default =~ "camera"
      assert phone_large =~ "phone-3"

      window_light =
        render_component(&Renderer.node/1,
          node: Registry.default_node("mockup_window", "default")
        )

      window_dark =
        render_component(&Renderer.node/1, node: Registry.default_node("mockup_window", "dark"))

      assert window_light =~ "mockup-window"
      assert window_light =~ "bg-base-100"
      assert window_dark =~ "mockup-window"
      assert window_dark =~ "bg-neutral"
    end

    test "mockup manifests are in Mockup group with slots and variants" do
      for name <- ~w(mockup_browser mockup_code mockup_phone mockup_window) do
        manifest = Registry.get!(name)
        assert manifest.group == "Mockup", "#{name} should be in Mockup group"
        assert manifest.variants != [], "#{name} should have variants"
        assert manifest.alpine == %{}, "#{name} should have no Alpine (static chrome)"
      end

      assert Registry.get!("mockup_browser").slots != []
      assert Registry.get!("mockup_window").slots != []
      assert Registry.get!("mockup_phone").slots != []
      assert Registry.get!("mockup_code").slots == []

      assert Registry.get!("mockup_browser").accepted_children != []
      assert Registry.get!("mockup_window").accepted_children != []
      assert Registry.get!("mockup_code").accepted_children == []
    end

    test "renders new typography components" do
      for name <-
            ~w(heading paragraph rich_text blockquote code_block ordered_list unordered_list text_gradient label_text) do
        html = render_component(&Renderer.node/1, node: Registry.default_node(name))
        assert html != "", "#{name} rendered empty"
      end

      assert render_component(&Renderer.node/1, node: Registry.default_node("heading")) =~
               "Your Heading Here"

      assert render_component(&Renderer.node/1, node: Registry.default_node("paragraph")) =~
               "Enter your paragraph"

      assert render_component(&Renderer.node/1, node: Registry.default_node("blockquote")) =~
               "inspiring quote"

      assert render_component(&Renderer.node/1, node: Registry.default_node("code_block")) =~
               "code"

      assert render_component(&Renderer.node/1, node: Registry.default_node("text_gradient")) =~
               "Gradient Text"

      assert render_component(&Renderer.node/1, node: Registry.default_node("label_text")) =~
               "Section Label"
    end

    test "typography manifests are in Typography group" do
      for name <-
            ~w(heading paragraph rich_text blockquote code_block ordered_list unordered_list text_gradient label_text) do
        manifest = Registry.get!(name)
        assert manifest.group == "Typography", "#{name} should be in Typography group"
        assert manifest.variants != [], "#{name} should have variants"
        assert manifest.fields != %{}, "#{name} should have fields"
      end
    end

    test "renders new media components" do
      for name <- ~w(image video audio gallery embed icon_block) do
        html = render_component(&Renderer.node/1, node: Registry.default_node(name))
        assert html != "", "#{name} rendered empty"
      end

      assert render_component(&Renderer.node/1, node: Registry.default_node("image")) =~
               "no-image-placeholder"

      assert render_component(&Renderer.node/1, node: Registry.default_node("gallery")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("icon_block")) =~
               "hero-star"
    end

    test "media manifests are in Media group" do
      for name <- ~w(image video audio gallery embed icon_block) do
        manifest = Registry.get!(name)
        assert manifest.group == "Media", "#{name} should be in Media group"
        assert manifest.variants != [], "#{name} should have variants"
      end

      assert Registry.get!("gallery").alpine != %{}
    end

    test "renders new layout components" do
      for name <- ~w(section container row column grid spacer) do
        html = render_component(&Renderer.node/1, node: Registry.default_node(name))
        assert html != "", "#{name} rendered empty"
      end
    end

    test "layout manifests are in Layout group with accepted children" do
      for name <- ~w(section container row column grid) do
        manifest = Registry.get!(name)
        assert manifest.group == "Layout", "#{name} should be in Layout group"
        assert manifest.accepted_children != [], "#{name} should accept children"
      end

      spacer = Registry.get!("spacer")
      assert spacer.group == "Layout"
      assert spacer.accepted_children == []
    end

    test "renders new content/marketing components" do
      for name <-
            ~w(feature_card feature_grid cta_section testimonial testimonial_grid pricing_card pricing_table team_member team_grid faq_section banner logo_grid steps_section empty_state notification_bar) do
        html = render_component(&Renderer.node/1, node: Registry.default_node(name))
        assert html != "", "#{name} rendered empty"
      end

      assert render_component(&Renderer.node/1, node: Registry.default_node("feature_card")) =~
               "Feature Title"

      assert render_component(&Renderer.node/1, node: Registry.default_node("cta_section")) =~
               "Ready to get started"

      assert render_component(&Renderer.node/1, node: Registry.default_node("pricing_card")) =~
               "Get started"

      assert render_component(&Renderer.node/1, node: Registry.default_node("faq_section")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("banner")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("notification_bar")) =~
               "x-data"
    end

    test "content manifests are in Content group" do
      for name <-
            ~w(feature_card feature_grid cta_section testimonial testimonial_grid pricing_card pricing_table team_member team_grid faq_section banner logo_grid steps_section empty_state notification_bar) do
        manifest = Registry.get!(name)
        assert manifest.group == "Content", "#{name} should be in Content group"
        assert manifest.variants != [], "#{name} should have variants"
      end
    end

    test "renders new interactive/utility components" do
      for name <-
            ~w(copy_button read_more scroll_to_top cookie_banner back_link share_buttons table_of_contents) do
        html = render_component(&Renderer.node/1, node: Registry.default_node(name))
        assert html != "", "#{name} rendered empty"
      end

      assert render_component(&Renderer.node/1, node: Registry.default_node("copy_button")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("read_more")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("scroll_to_top")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("cookie_banner")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("back_link")) =~
               "Back"

      assert render_component(&Renderer.node/1, node: Registry.default_node("table_of_contents")) =~
               "Contents"
    end

    test "interactive manifests are in Interactive group" do
      for name <-
            ~w(copy_button read_more scroll_to_top cookie_banner back_link share_buttons table_of_contents) do
        manifest = Registry.get!(name)
        assert manifest.group == "Interactive", "#{name} should be in Interactive group"
        assert manifest.variants != [], "#{name} should have variants"
      end
    end

    test "renders data display batch one defaults and bindings" do
      assert render_component(&Renderer.node/1, node: Registry.default_node("accordion")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("card", "collection")) =~
               "{{item.title}}"

      assert render_component(&Renderer.node/1, node: Registry.default_node("carousel")) =~
               "x-data"

      assert render_component(&Renderer.node/1, node: Registry.default_node("collapse", "plus")) =~
               "collapse-plus"

      assert render_component(&Renderer.node/1, node: Registry.default_node("list")) =~
               "{{item.excerpt}}"

      assert render_component(&Renderer.node/1, node: Registry.default_node("stat")) =~
               "{{item.value}}"

      assert render_component(&Renderer.node/1, node: Registry.default_node("table")) =~
               "table-zebra"

      assert render_component(&Renderer.node/1,
               node: Registry.default_node("timeline", "horizontal")
             ) =~
               "timeline-horizontal"
    end
  end
end
