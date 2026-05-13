defmodule MangoCMSWeb.Platform.Admin.UserLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform.Accounts

  @create_attrs %{
    full_name: "Managed Platform User",
    email: "managed-platform-user@example.com",
    password: "valid-password-123",
    role: "editor",
    phone: "+15550000001",
    avatar_url: "https://example.com/platform-user.png",
    locale: "en",
    timezone: "UTC"
  }

  @update_attrs %{
    full_name: "Updated Platform User",
    email: "updated-platform-user@example.com",
    password: "",
    role: "viewer",
    phone: "+15550000002",
    avatar_url: "https://example.com/platform-user-updated.png",
    locale: "en",
    timezone: "Asia/Kolkata"
  }

  @invalid_attrs %{
    full_name: "",
    email: "",
    password: "short",
    role: "editor"
  }

  defp unique_email(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}@example.com"
  end

  defp managed_platform_user_fixture(attrs \\ %{}) do
    attrs =
      @create_attrs
      |> Map.put(:email, unique_email("managed-platform"))
      |> Map.merge(attrs)

    {:ok, user} = Accounts.create_user(attrs)
    user
  end

  setup %{conn: conn} do
    {conn, user} = register_and_log_in_platform_user(conn)
    %{conn: conn, platform_user: user}
  end

  describe "Index" do
    test "lists platform users", %{conn: conn, platform_user: platform_user} do
      {:ok, _index_live, html} = live(conn, ~p"/platform/admin/users")

      assert html =~ "Platform users"
      assert html =~ platform_user.email
      assert html =~ "id=\"new-platform-user-button\""
    end

    test "creates platform user", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/users")

      assert index_live |> element("#new-platform-user-button") |> render_click() =~
               "New platform user"

      assert index_live
             |> form("#platform-user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      attrs = Map.put(@create_attrs, :email, unique_email("new-platform"))

      assert index_live
             |> form("#platform-user-form", user: attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/platform/admin/users")
      assert render(index_live) =~ attrs.full_name
    end

    test "updates platform user", %{conn: conn} do
      user = managed_platform_user_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/users")

      assert index_live |> element("#edit-platform-user-#{user.id}") |> render_click() =~
               "Edit platform user"

      attrs = Map.put(@update_attrs, :email, unique_email("updated-platform"))

      assert index_live
             |> form("#platform-user-form", user: attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/platform/admin/users")
      html = render(index_live)
      assert html =~ "Updated Platform User"
      refute html =~ user.email
    end

    test "deletes platform user but not the current user", %{
      conn: conn,
      platform_user: platform_user
    } do
      user = managed_platform_user_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/users")

      assert index_live |> element("#delete-platform-user-#{user.id}") |> render_click()
      refute has_element?(index_live, "#users-#{user.id}")

      assert index_live
             |> element("#delete-platform-user-#{platform_user.id}")
             |> render_click() =~ "You cannot delete your own account."

      assert has_element?(index_live, "#users-#{platform_user.id}")
    end
  end
end
