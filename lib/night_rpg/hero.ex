defmodule NightRPG.Hero do
  @moduledoc """
  A GenServer process used to keep track of an individual hero. It is responsible for:
  - Checking to see if a move if valid
  - Broadcasting attacks
  - Listening to attacks and dying to fatal attacks
  - Respawning when told

  A hero's state consists of it's position and it's life
  """

  use GenServer
  alias NightRPG.{Board, Game, Hero}
  alias NightRPGWeb.Presence

  # Client
  def start_link(%{name: name, game: game}) do
    state = %{game: game, name: name, coords: nil}
    GenServer.start_link(__MODULE__, state, name: Game.hero_tuple(game, name))
  end

  def move(pid, :left), do: GenServer.cast(pid, {:move, [-1, 0]})
  def move(pid, :up), do: GenServer.cast(pid, {:move, [0, -1]})
  def move(pid, :right), do: GenServer.cast(pid, {:move, [1, 0]})
  def move(pid, :down), do: GenServer.cast(pid, {:move, [0, 1]})

  def move(game, name, direction) do
    {:ok, pid} = Game.lookup_hero(game, name)
    Hero.move(pid, direction)
  end

  def dodge(pid, coords, from) do
    GenServer.cast(pid, {:dodge, coords, from})
  end

  def respawn(pid) do
    GenServer.cast(pid, :respawn)
  end

  def alive(pid) do
    GenServer.call(pid, :alive)
  end

  def state(pid) do
    try do
      GenServer.call(pid, :state)
    catch
      :exit, {:noproc, _} -> :error
    end
  end

  # Server

  def init(state) do
    NightRPGWeb.Endpoint.subscribe(Game.topic(state.game))
    {:ok, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:alive, _from, state) do
    {:reply, state.coords != nil, state}
  end

  def handle_cast({:move, [dx, dy]}, state) do
    [x, y] = state.coords
    next_coords = [x + dx, y + dy]
    {:ok, board_pid} = Game.which_board(state.game)

    if Board.is_movable?(board_pid, next_coords) do
      {:noreply, %{state | coords: next_coords}}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:dodge, coords, from}, state) do
    if state.name != from && state.coords != nil && in_range(coords, state.coords) do
      {:noreply, %{state | coords: nil}}
    else
      {:noreply, state}
    end
  end

  def handle_cast(:respawn, state) do
    unless state.coords do
      {:ok, board_pid} = Game.which_board(state.game)
      coords = Board.random_movable_tile(board_pid)

      {:noreply, %{state | coords: coords}}
    else
      {:noreply, state}
    end
  end

  def handle_info(%{event: "presence_diff", topic: topic}, state) do
    hero_has_user? =
      topic
      |> Presence.list()
      |> Enum.find(fn {_id, data} ->
        state.name == data
        |> Map.get(:metas, [%{}])
        |> List.first()
        |> Map.get(:name)
      end)

    if hero_has_user? do
      {:noreply, state}
    else
      {:stop, :shutdown, state}
    end
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp in_range([x1, y1], [x2, y2]) do
    Enum.member?(-1..1, x1 - x2) && Enum.member?(-1..1, y1 - y2)
  end
end
