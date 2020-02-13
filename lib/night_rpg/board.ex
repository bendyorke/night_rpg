defmodule NightRPG.Board do
  @moduledoc """
  A GenServer process used to keep track of the state of a board. It is responsible for:
  - Randomly placing a character
  - Checking to see if a player can move to a specific tile
  - Respawning dead players
  - Keeping track of all players in a game

  A board's state consists of it's tiles, a two dimensional array consisting of 1's and 0's,
  where 1's are walls and 0's are moveable tiles
  """

  use GenServer
  alias NightRPG.{Game,Hero}

  @default_tiles [
    [1, 1, 1, 1, 1],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [1, 0, 0, 0, 1],
    [1, 1, 1, 1, 1]
  ]

  @default_respawn_interval 5_000

  # Client

  def start_link(game, opts \\ %{}) do
    tiles = Map.get(opts, :tiles, @default_tiles)
    respawn_interval = Map.get(opts, :respawn_interval, @default_respawn_interval)

    GenServer.start_link(__MODULE__, %{
      game: game,
      respawn_interval: respawn_interval,
      respawns: 0,
      tiles: tiles
    })
  end

  def is_movable?(pid, [x, y]) do
    GenServer.call(pid, {:check, [x, y]})
  end

  def random_movable_tile(pid) do
    GenServer.call(pid, :random_movable_tile)
  end

  def respawns(pid) do
    GenServer.call(pid, :get_respawns_count)
  end

  defp schedule_respawn(interval) do
    Process.send_after(self(), :respawn, interval)
  end

  # Server

  def init(state) do
    schedule_respawn(state.respawn_interval)

    {:ok, state}
  end

  def handle_info(:respawn, state) do
    # send respawn trigger
    {:ok, pids} = Game.which_heros(state.game)
    Enum.each(pids, &Hero.respawn/1)

    schedule_respawn(state.respawn_interval)
    {:noreply, Map.update(state, :respawns, 0, &(&1 + 1))}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:check, [x, y]}, _from, state) do
    value = value_at(state.tiles, [x, y])

    {:reply, value == 0, state}
  end

  def handle_call(:random_movable_tile, _from, state) do
    coord = get_tile_with_value(state.tiles, 0)

    {:reply, coord, state}
  end

  def handle_call(:get_respawns_count, _from, state) do
    {:reply, state.respawns, state}
  end

  # Private

  defp get_tile_with_value(tiles, value) do
    coord = random_coord(tiles)

    if value_at(tiles, coord) == value do
      coord
    else
      get_tile_with_value(tiles, value)
    end
  end

  defp random_coord(tiles) do
    random_y = random_index(tiles)

    random_x =
      tiles
      |> Enum.at(random_y)
      |> random_index()

    [random_x, random_y]
  end

  defp random_index(list) do
    entry =
      list
      |> Enum.count()
      |> Range.new(1)
      |> Enum.random()

    entry - 1
  end

  defp value_at(tiles, [x, y]) do
    tiles
    |> Enum.at(y, [])
    |> Enum.at(x)
  end
end
