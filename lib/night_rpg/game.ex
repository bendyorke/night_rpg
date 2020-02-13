defmodule NightRPG.Game do
  use DynamicSupervisor

  alias NightRPG.{Game, Board, Hero}

  def via_tuple(name), do: {:via, Registry, {:games, name}}
  def hero_tuple(name, hero_name), do: {:via, Registry, {:heroes, "#{name} #{hero_name}"}}

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
        DynamicSupervisor.start_child(via_tuple(name), hero_init(name, hero_name))
    end
  end

  def start_game(name) do
    case Game.start_link(name) do
      {:ok, pid} ->
        DynamicSupervisor.start_child(via_tuple(name), board_init())
        {:ok, pid}
      error ->
        error
    end
  end

  def which_board(name) do
    {_, pid, _, _} = name
    |> via_tuple()
    |> DynamicSupervisor.which_children()
    |> Enum.find(fn {_, _, _, [type]} -> type == Board end)

    {:ok, pid}
  end

  def which_heros(name) do
    pids = name
    |> via_tuple()
    |> DynamicSupervisor.which_children()
    |> Enum.filter(fn {_, _, _, [type]} -> type == Hero end)
    |> Enum.map(fn {_, pid, _, _} -> pid end)

    {:ok, pids}
  end

  def start_link(name) do
    DynamicSupervisor.start_link(__MODULE__, [], name: via_tuple(name))
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def supervisor_init(name), do: {Registry, keys: :unique, name: name}

  def board_init() do
    %{
      id: Board,
      start: {Board, :start_link, [%{}]},
      restart: :transient,
    }
  end

  def hero_init(name, hero_name) do
    %{
      id: hero_name,
      # start: {Hero, :start_link, [%{board_pid: board_pid}]},
      start: {Hero, :start_link, [name, hero_name]},
      restart: :transient,
    }
  end
end