defmodule NightRPG.BoardTest do
  use ExUnit.Case, async: true

  alias NightRPG.Board

  @test_tiles [
    [1, 1, 1, 1, 1],
    [1, 0, 0, 0, 1],
    [1, 1, 1, 1, 1]
  ]

  setup do
    start_supervised!({NightRPG.Game, "test"})
    pid = start_supervised!({Board, %{tiles: @test_tiles, respawn_interval: 10, game: "test"}})
    %{pid: pid}
  end

  test "can check whether a given tile is movable to", %{pid: pid} do
    assert Board.is_movable?(pid, [0, 0]) == false
    assert Board.is_movable?(pid, [1, 1]) == true
  end

  test "can return a random movable tile", %{pid: pid} do
    Enum.each(1..100, fn _x ->
      [x, y] = Board.random_movable_tile(pid)

      assert x > 0 and x < 4
      assert y == 1
    end)
  end

  test "respawns on an interval and tracks the count", %{pid: pid} do
    respawns_1 = Board.respawns(pid)
    :timer.sleep(10)
    respawns_2 = Board.respawns(pid)

    assert respawns_2 > respawns_1
  end
end
