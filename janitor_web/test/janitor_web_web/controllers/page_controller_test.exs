defmodule JanitorWeb.PageControllerTest do
  use JanitorWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 302) =~ "You are being"
  end
end
