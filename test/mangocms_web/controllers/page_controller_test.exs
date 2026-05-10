defmodule MangoCMSWeb.PageControllerTest do
  use MangoCMSWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "Launch a polished website on #{MangoCMSWeb.Brand.name()}"
    assert html =~ "Create your company profile website"
    assert html =~ "Added AI chat feature"
    assert html =~ "id=\"plans\""
    assert html =~ "id=\"reviews\""
  end
end
