defmodule NightRPG.HeroTest do
  use ExUnit.Case, async: true

  alias NightRPG.{Board, Hero}

  @test_tiles [
    [1, 1, 1, 1],
    [1, 0, 0, 1],
    [1, 0, 0, 1],
    [1, 1, 1, 1]
  ]

  setup do
    board_pid = start_supervised!({Board, %{tiles: @test_tiles}})
    pid = start_supervised!({Hero, %{board_pid: board_pid}})
    %{pid: pid, board_pid: board_pid}
  end

  test "gets placed on a random tile", %{pid: pid, board_pid: board_pid} do
    coords = Hero.coords(pid)

    assert coords != nil
    assert is_list(coords)
    assert Board.is_movable?(board_pid, coords)
  end

  test "hero can move in all 4 direction", %{pid: pid} do
    Enum.each(1..4, fn _ ->
      case Hero.coords(pid) do
        [1, 1] ->
          Hero.move(pid, :right)
          assert Hero.coords(pid) == [2, 1]

        [2, 1] ->
          Hero.move(pid, :down)
          assert Hero.coords(pid) == [2, 2]

        [2, 2] ->
          Hero.move(pid, :left)
          assert Hero.coords(pid) == [1, 2]

        [1, 2] ->
          Hero.move(pid, :up)
          assert Hero.coords(pid) == [1, 1]
      end
    end)
  end

  test "hero can only move onto walkable tiles", %{pid: pid, board_pid: board_pid} do
    Enum.each(1..10_000, fn _ ->
      direction = Enum.random([:left, :up, :right, :down])
      Hero.move(pid, direction)
      assert Board.is_movable?(board_pid, Hero.coords(pid))
    end)
  end

  test "hero can attack without being hit himself", %{pid: pid} do
    assert Hero.alive(pid) == true
    Hero.attack(pid)
    assert Hero.alive(pid) == true
  end

  test "hero is hurt when in range of attacks", %{pid: pid, board_pid: board_pid} do
    assert Hero.alive(pid) == true

    # Ensure hero is in top left corner
    Hero.move(pid, :up)
    Hero.move(pid, :left)

    Hero.dodge(pid, [3, 3])
    assert Hero.alive(pid) == true

    Hero.dodge(pid, [2, 2])
    assert Hero.alive(pid) == false
  end

  test "hero can be respawned", %{pid: pid} do
    assert Hero.alive(pid) == true
    Hero.dodge(pid, Hero.coords(pid))
    assert Hero.alive(pid) == false
    Hero.respawn(pid)
    assert Hero.alive(pid) == true
  end
end
