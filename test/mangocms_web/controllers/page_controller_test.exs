defmodule MangoCMSWeb.PageControllerTest do
  use MangoCMSWeb.ConnCase

  defp with_platform_registration_enabled(fun) do
    previous = Application.get_env(:mangocms, :platform_admin_registration, [])
    Application.put_env(:mangocms, :platform_admin_registration, enabled: true)

    try do
      fun.()
    after
      Application.put_env(:mangocms, :platform_admin_registration, previous)
    end
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "Launch a polished website on #{MangoCMSWeb.Brand.name()}"
    assert html =~ "Create your company profile website"
    assert html =~ "Added AI chat feature"
    assert html =~ "id=\"plans\""
    assert html =~ "id=\"reviews\""
    assert html =~ ~p"/platform/login"
    assert html =~ ~p"/platform/register"
    refute html =~ ~p"/platform/admin/register"
  end

  test "GET / keeps platform admin registration hidden when enabled", %{conn: conn} do
    with_platform_registration_enabled(fn ->
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ ~p"/platform/register"
      refute html =~ ~p"/platform/admin/register"
    end)
  end

  test "GET / shows current platform user name", %{conn: conn} do
    {conn, user} = register_and_log_in_platform_user(conn)

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ user.full_name
  end
end
