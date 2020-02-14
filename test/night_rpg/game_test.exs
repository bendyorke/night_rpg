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
    assert pid == pid_2
    {:ok, pid_3} = Game.connect(@game <> "2")
    assert pid != pid_3

    DynamicSupervisor.stop(pid_3, :shutdown)
  end

  test "a game is started with a board and no heros", %{pid: _pid} do
    assert {:ok, pid} = Game.which_board(@game)
    assert pid != nil
    assert {:ok, []} = Game.which_heroes(@game)
  end
end
