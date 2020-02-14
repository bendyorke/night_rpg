defmodule NightRPG.HeroTest do
  use ExUnit.Case

  alias NightRPG.{Game, Board, Hero}

  @test_tiles [
    [1, 1, 1, 1],
    [1, 0, 0, 1],
    [1, 0, 0, 1],
    [1, 1, 1, 1]
  ]

  @game "test"
  @hero "hero"

  setup do
    {:ok, game_pid} = Game.start_game(@game, %{tiles: @test_tiles})
    pid = start_supervised!({Hero, %{game: @game, name: @hero}})

    on_exit(fn ->
      :ok = DynamicSupervisor.stop(game_pid, :shutdown)
    end)

    %{pid: pid, game_pid: game_pid}
  end

  test "gets placed on a random tile after respawn", %{pid: pid} do
    state = GenServer.call(pid, :state)
    assert state.coords == nil

    Hero.respawn(pid)

    state = GenServer.call(pid, :state)
    assert state.coords != nil
    assert is_list(state.coords)

    {:ok, board_pid} = Game.which_board(@game)
    assert Board.is_movable?(board_pid, state.coords)
  end

  test "hero can move in all 4 direction", %{pid: pid} do
    Hero.respawn(pid)

    Enum.each(1..4, fn _ ->
      case GenServer.call(pid, :state).coords do
        [1, 1] ->
          Hero.move(pid, :right)
          assert GenServer.call(pid, :state).coords == [2, 1]

        [2, 1] ->
          Hero.move(pid, :down)
          assert GenServer.call(pid, :state).coords == [2, 2]

        [2, 2] ->
          Hero.move(pid, :left)
          assert GenServer.call(pid, :state).coords == [1, 2]

        [1, 2] ->
          Hero.move(pid, :up)
          assert GenServer.call(pid, :state).coords == [1, 1]
      end
    end)
  end

  test "hero can only move onto walkable tiles", %{pid: pid} do
    Hero.respawn(pid)

    Enum.each(1..10_000, fn _ ->
      direction = Enum.random([:left, :up, :right, :down])
      Hero.move(pid, direction)
      state = GenServer.call(pid, :state)
      {:ok, board_pid} = Game.which_board(@game)
      assert Board.is_movable?(board_pid, state.coords)
    end)
  end

  test "hero can attack without being hit himself", %{pid: pid} do
    Hero.respawn(pid)
    assert Hero.alive(pid) == true
    Hero.dodge(pid, [1, 1], @hero)
    assert Hero.alive(pid) == true
  end

  test "hero is hurt when in range of attacks", %{pid: pid} do
    Hero.respawn(pid)
    assert Hero.alive(pid) == true

    # Ensure hero is in top left corner
    Hero.move(pid, :up)
    Hero.move(pid, :left)

    Hero.dodge(pid, [3, 3], "not_" <> @hero)
    assert Hero.alive(pid) == true

    Hero.dodge(pid, [2, 2], "not_" <> @hero)
    assert Hero.alive(pid) == false
  end

  test "hero can be respawned", %{pid: pid} do
    assert GenServer.call(pid, :state).coords == nil
    Hero.respawn(pid)
    assert GenServer.call(pid, :state).coords != nil
    Hero.dodge(pid, [1, 1], "not_" <> @hero)
    assert GenServer.call(pid, :state).coords == nil
    Hero.respawn(pid)
    assert GenServer.call(pid, :state).coords != nil
  end
end
