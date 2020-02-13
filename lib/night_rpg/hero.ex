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
  alias NightRPG.Board

  # Client

  def start_link(args) do
    board_pid = Map.get(args, :board_pid)

    GenServer.start_link(__MODULE__, %{alive: true, board_pid: board_pid})
  end

  def coords(pid) do
    GenServer.call(pid, :get_coords)
  end

  def move(pid, :left), do: GenServer.cast(pid, {:move, [-1, 0]})
  def move(pid, :up), do: GenServer.cast(pid, {:move, [0, -1]})
  def move(pid, :right), do: GenServer.cast(pid, {:move, [1, 0]})
  def move(pid, :down), do: GenServer.cast(pid, {:move, [0, 1]})

  def attack(pid) do
    GenServer.cast(pid, :attack)
  end

  def dodge(pid, coords) do
    GenServer.cast(pid, {:dodge, coords})
  end

  def respawn(pid) do
    GenServer.cast(pid, :respawn)
  end

  def alive(pid) do
    GenServer.call(pid, :alive)
  end

  # Server

  def init(state) do
    coords = Board.random_movable_tile(state.board_pid)
    {:ok, Map.put(state, :coords, coords)}
  end

  def handle_call(:alive, _from, state) do
    {:reply, state.alive, state}
  end

  def handle_call(:get_coords, _from, state) do
    {:reply, state.coords, state}
  end

  def handle_cast({:move, [dx, dy]}, state) do
    [x, y] = state.coords
    next_coords = [x + dx, y + dy]

    if Board.is_movable?(state.board_pid, next_coords) do
      {:noreply, %{state | coords: next_coords}}
    else
      {:noreply, state}
    end
  end

  def handle_cast(:attack, state) do
    {:noreply, state}
  end

  def handle_cast({:dodge, coords}, state) do
    if in_range(coords, state.coords) do
      {:noreply, %{state | alive: false}}
    else
      {:noreply, state}
    end
  end

  def handle_cast(:respawn, state) do
    coords = Board.random_movable_tile(state.board_pid)

    {:noreply, %{state | alive: true, coords: coords}}
  end

  defp in_range([x1, y1], [x2, y2]) do
    Enum.member?(-1..1, x1 - x2) && Enum.member?(-1..1, y1 - y2)
  end
end
