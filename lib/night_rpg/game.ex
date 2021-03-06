defmodule NightRPG.Game do
  use DynamicSupervisor

  alias NightRPG.{GamesSupervisor, Game, Board, Hero}

  # Client

  def via_tuple(name), do: {:via, Registry, {:games, name}}
  def hero_tuple(name, hero_name), do: {:via, Registry, {:heroes, "#{name} #{hero_name}"}}
  def subscribe(name), do: Phoenix.PubSub.subscribe(NightRPG.PubSub, name)
  def broadcast_update(name), do: Phoenix.PubSub.broadcast(NightRPG.PubSub, name, :update)
  def topic(name), do: "game:" <> name

  def connect(name) do
    case Registry.lookup(:games, name) do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        NightRPG.Game.start_game(name)
    end
  end

  def join(name, hero_name) do
    case Registry.lookup(:heroes, "#{name} #{hero_name}") do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        {:ok, pid} = DynamicSupervisor.start_child(via_tuple(name), hero_init(name, hero_name))
        broadcast_update(name)
        {:ok, pid}
    end
  end

  def state(name) do
    {:ok, board_pid} = Game.which_board(name)
    {:ok, hero_pids} = Game.which_heroes(name)

    {
      Board.state(board_pid),
      hero_pids
      |> Enum.map(&Hero.state/1)
      |> Enum.filter(&(&1 != :error))
    }
  end

  def lookup_hero(game, name) do
    case Registry.lookup(:heroes, "#{game} #{name}") do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        {:error, :no_hero_found}
    end
  end

  def which_children(name) do
    name
    |> via_tuple()
    |> DynamicSupervisor.which_children()
  end

  def which_board(name) do
    board_child =
      name
      |> which_children
      |> Enum.find(fn {_, _, _, [type]} -> type == Board end)

    pid =
      case board_child do
        {_, pid, _, _} -> pid
        _ -> nil
      end

    {:ok, pid}
  end

  def which_heroes(name) do
    pids =
      name
      |> which_children()
      |> Enum.filter(fn {_, _, _, [type]} -> type == Hero end)
      |> Enum.map(fn {_, pid, _, _} -> pid end)

    {:ok, pids}
  end

  def start_game(name, board_opts \\ %{}) do
    case DynamicSupervisor.start_child(GamesSupervisor, game_init(name)) do
      {:ok, pid} ->
        DynamicSupervisor.start_child(via_tuple(name), board_init(name, board_opts))
        {:ok, pid}

      error ->
        error
    end
  end

  # Server

  def start_link(name) do
    DynamicSupervisor.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def init(_name) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Private

  defp game_init(name) do
    %{
      id: Game,
      start: {Game, :start_link, [name]},
      restart: :transient
    }
  end

  defp board_init(name, board_opts) do
    %{
      id: Board,
      start: {Board, :start_link, [Map.put(board_opts, :game, name)]},
      restart: :transient
    }
  end

  defp hero_init(name, hero_name) do
    %{
      id: hero_name,
      start: {Hero, :start_link, [%{game: name, name: hero_name}]},
      restart: :transient
    }
  end
end
