defmodule NightRPG.GameTest do
  use ExUnit.Case

  alias NightRPG.{Game}

  @game "test"

  setup do
    {:ok, pid} = Game.connect(@game)

    on_exit(fn ->
      :ok = DynamicSupervisor.stop(pid, :shutdown)
    end)

    %{pid: pid}
  end

  test "connect will join a game in a registry or create a new one", %{pid: pid} do
    {:ok, pid_2} = Game.connect(@game)
    {:ok, pid_3} = Game.connect(@game <> "2")
    assert pid == pid_2
    assert pid != pid_3

    DynamicSupervisor.stop(pid_3, :shutdown)
  end

  test "a game is started with a board and no heros" do
    assert {:ok, pid} = Game.which_board(@game)
    assert pid != nil
    assert {:ok, []} = Game.which_heroes(@game)
  end

  test "heroes can join a game with unique names" do
    assert {:ok, pid_1} = Game.join(@game, "one")
    assert {:ok, pid_2} = Game.join(@game, "one")
    assert {:ok, pid_3} = Game.join(@game, "two")
    assert pid_1 == pid_2
    assert pid_1 != pid_3
    assert {:ok, pids} = Game.which_heroes(@game)
    assert Enum.count(pids) == 2
  end

  test "a game can find a given hero" do
    {:ok, pid_1} = Game.join(@game, "hero")
    assert {:ok, pid_2} = Game.lookup_hero(@game, "hero")
    assert pid_1 == pid_2
    assert {:error, :no_hero_found} = Game.lookup_hero(@game, "no_hero")
  end
end
