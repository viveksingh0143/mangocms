defmodule MangoCMS.ContentTreeTest do
  use ExUnit.Case, async: true

  alias MangoCMS.ContentTree

  defp fixture_tree do
    [
      %{
        "type" => "component",
        "name" => "section",
        "id" => "sect_hero",
        "path" => "stale",
        "props" => %{"label" => "Hero"},
        "classes" => %{"display" => "w-full"},
        "children" => [
          %{
            "type" => "component",
            "name" => "row",
            "id" => "row_main",
            "path" => "stale",
            "props" => %{"gutter" => "default"},
            "classes" => %{"display" => "grid grid-cols-12"},
            "children" => [
              %{
                "type" => "component",
                "name" => "column",
                "id" => "col_copy",
                "path" => "stale",
                "props" => %{"span" => "6"},
                "classes" => %{"display" => "col-span-6"},
                "children" => [
                  %{
                    "type" => "component",
                    "name" => "heading",
                    "id" => "heading_title",
                    "path" => "stale",
                    "props" => %{"text" => "Build faster"},
                    "classes" => %{"daisy_ui" => "text-5xl"}
                  }
                ]
              },
              %{
                "type" => "component",
                "name" => "column",
                "id" => "col_media",
                "path" => "stale",
                "props" => %{"span" => "6"},
                "classes" => %{"display" => "col-span-6"},
                "children" => [
                  %{
                    "type" => "component",
                    "name" => "button",
                    "id" => "button_cta",
                    "path" => "stale",
                    "props" => %{"text" => "Get started", "href" => "/signup"},
                    "classes" => %{"daisy_ui" => "btn btn-primary"}
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  end

  defp new_image_node do
    %{
      "type" => "component",
      "name" => "image",
      "id" => "image_logo",
      "path" => "root.sect_hero.row_main.col_media",
      "props" => %{"src" => "/uploads/logo.png"},
      "classes" => %{"display" => "w-full"}
    }
  end

  describe "find_node/2" do
    test "finds nested nodes by id" do
      assert %{"name" => "button", "props" => %{"href" => "/signup"}} =
               ContentTree.find_node(fixture_tree(), "button_cta")
    end

    test "returns nil when the id is missing" do
      refute ContentTree.find_node(fixture_tree(), "missing")
    end
  end

  describe "update_node_props/3" do
    test "merges props and normalizes materialized paths" do
      tree =
        fixture_tree()
        |> ContentTree.update_node_props("button_cta", %{"target" => "_blank"})

      assert %{
               "path" => "root.sect_hero.row_main.col_media",
               "props" => %{
                 "text" => "Get started",
                 "href" => "/signup",
                 "target" => "_blank"
               }
             } = ContentTree.find_node(tree, "button_cta")
    end
  end

  describe "update_node_classes/3" do
    test "merges categorized classes without losing existing categories" do
      tree =
        fixture_tree()
        |> ContentTree.update_node_classes("heading_title", %{"margin" => "mt-6"})

      assert %{
               "classes" => %{
                 "daisy_ui" => "text-5xl",
                 "margin" => "mt-6"
               }
             } = ContentTree.find_node(tree, "heading_title")
    end
  end

  describe "delete_node/2" do
    test "removes a node and all descendants" do
      tree = ContentTree.delete_node(fixture_tree(), "col_copy")

      refute ContentTree.find_node(tree, "col_copy")
      refute ContentTree.find_node(tree, "heading_title")
      assert ContentTree.find_node(tree, "button_cta")
    end
  end

  describe "insert_node/4" do
    test "inserts a node into a container and normalizes paths" do
      tree = ContentTree.insert_node(fixture_tree(), "col_media", new_image_node(), :into)

      assert %{"path" => "root.sect_hero.row_main.col_media"} =
               ContentTree.find_node(tree, "image_logo")
    end

    test "inserts a node at the root" do
      tree = ContentTree.insert_node(fixture_tree(), "root", new_image_node(), :into)

      assert %{"path" => "root"} = ContentTree.find_node(tree, "image_logo")
    end
  end

  describe "move_node/4" do
    test "moves a node into another container and updates descendant paths" do
      tree = ContentTree.move_node(fixture_tree(), "col_copy", "sect_hero", :into)

      assert %{"path" => "root.sect_hero"} = ContentTree.find_node(tree, "col_copy")
      assert %{"path" => "root.sect_hero.col_copy"} = ContentTree.find_node(tree, "heading_title")
    end

    test "moves a node before a target sibling position" do
      tree = ContentTree.move_node(fixture_tree(), "button_cta", "heading_title", :before)

      assert %{"path" => "root.sect_hero.row_main.col_copy"} =
               ContentTree.find_node(tree, "button_cta")

      col_copy = ContentTree.find_node(tree, "col_copy")

      assert [
               %{"id" => "button_cta"},
               %{"id" => "heading_title"}
             ] = col_copy["children"]
    end

    test "moves a node after a target sibling position" do
      tree = ContentTree.move_node(fixture_tree(), "button_cta", "heading_title", :after)
      col_copy = ContentTree.find_node(tree, "col_copy")

      assert [
               %{"id" => "heading_title"},
               %{"id" => "button_cta"}
             ] = col_copy["children"]
    end

    test "moves a nested node to the root" do
      tree = ContentTree.move_node(fixture_tree(), "button_cta", "root", :into)

      assert %{"path" => "root"} = ContentTree.find_node(tree, "button_cta")
    end

    test "rejects missing ids and self-descendant moves without changing the tree" do
      original = fixture_tree()

      assert ContentTree.move_node(original, "missing", "heading_title", :before) == original
      assert ContentTree.move_node(original, "sect_hero", "heading_title", :into) == original
      assert ContentTree.move_node(original, "button_cta", "button_cta", :into) == original
    end
  end

  describe "diff_trees/2" do
    test "reports added, removed, and changed nodes by id" do
      tree_a = fixture_tree() |> ContentTree.update_node_props("button_cta", %{})

      tree_b =
        tree_a
        |> ContentTree.update_node_props("heading_title", %{"text" => "Launch faster"})
        |> ContentTree.delete_node("button_cta")

      col_media = ContentTree.find_node(tree_b, "col_media")

      tree_b =
        ContentTree.update_node_props(
          [
            put_in(
              hd(tree_b),
              ["children", Access.at(0), "children", Access.at(1)],
              Map.put(col_media, "children", [new_image_node()])
            )
          ],
          "image_logo",
          %{}
        )

      diff = ContentTree.diff_trees(tree_a, tree_b)

      assert diff.added == ["image_logo"]
      assert diff.removed == ["button_cta"]
      assert diff.changed == ["heading_title"]
    end
  end
end
