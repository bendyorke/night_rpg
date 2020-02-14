defmodule NightRPGWeb.PageControllerTest do
  use NightRPGWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to NightRPG!"
  end
end
