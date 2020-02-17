defmodule NightRPGWeb.GameControllerTest do
  use NightRPGWeb.ConnCase

  @game "game"
  @hero "hero"

  test "joins a game at a given path", %{conn: conn} do
    conn = get(conn, "/" <> @game)
    assert html_response(conn, 200) =~ @game
  end

  test "uses custom names passed in as query params", %{conn: conn} do
    conn = get(conn, "/#{@game}?name=#{@hero}")
    assert html_response(conn, 200) =~ "controlling #{@hero}"
  end

  test "assigns a random name if none is provided", %{conn: conn} do
    conn = get(conn, "/#{@game}")
    assert html_response(conn, 200) =~ ~r/controlling [a-z]{8}/
  end
end
