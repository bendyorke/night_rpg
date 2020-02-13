defmodule NightRPGWeb.GameLive do
  use Phoenix.LiveView
  alias NightRPG.Game

  def render(assigns) do
    ~L"""
    Welcome to the live <%= @game %> game, <%= @name %>!
    <%= for {row, y} <- Enum.with_index(@board.tiles) do %>
      <div>
        <%= for {_, x} <- Enum.with_index(row) do %>
          <%= render_tile assigns, x, y %>
        <% end %>
      </div>
    <% end %>

    <%= render_waiting_players assigns %>
    """
  end

  def render_tile(assigns, x, y) do
    status = status_at_tile(assigns, x, y)
    ~L"""
    <span style="border: 1px solid grey">
      <%= status %>
    </span>
    """
  end

  def render_waiting_players(assigns) do
    waiting_players =
      assigns.heroes
      |> Enum.filter(fn x -> x.coords == nil end)

    ~L"""
    <div>
      Waiting players:
      <%= for player <- waiting_players do %>
        <div><%= player.name %></div>
      <% end %>
    </div>
    """
  end

  def mount(params, _session, socket) do
    game = Map.get(params, "game")
    name = Map.get(params, "name", generate_random_name())

    {:ok, _pid} = Game.connect(game)
    {:ok, _pid} = Game.join(game, name)
    {board, heroes} = Game.state(game) |> IO.inspect

    {:ok, assign(socket, game: game, name: name, board: board, heroes: heroes)}
  end

  def generate_random_name() do
    name =
      ?a..?z
      |> Enum.take_random(8)
      |> List.to_string()
  end

  def status_at_tile(assigns, x, y) do
    board = assigns.board
    heroes = assigns.heroes
    cond do
      Enum.any?(heroes, fn p -> p.name == assigns.name && p.coords == [x, y] end) ->
        :hero
      Enum.any?(heroes, fn p -> p.coords == [x, y] end) ->
        :enemy
      value_at(board.tiles, [x, y]) == 1 ->
        :wall
      value_at(board.tiles, [x, y]) == 0 ->
        :floor
    end
  end

  def value_at(tiles, [x, y]) do
    tiles
    |> Enum.at(y)
    |> Enum.at(x)
  end
end
