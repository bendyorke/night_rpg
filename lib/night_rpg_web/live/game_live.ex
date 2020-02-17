defmodule NightRPGWeb.GameLive do
  use Phoenix.LiveView
  alias NightRPG.{Game, Hero}
  alias NightRPGWeb.Presence

  def render(assigns) do
    ~L"""
    <div class="game" phx-window-keyup="keyup">
      <header>
        <h1><%= @game %></h1>
        <%= if @joined do %>
          <p>controlling <%= @name %></p>
        <% end %>
      </header>

      <div class="board">
        <%= for {row, y} <- Enum.with_index(@board.tiles) do %>
          <div class="row">
            <%= for {_, x} <- Enum.with_index(row) do %>
              <%= render_tile assigns, x, y %>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="respawn-pool">
        Waiting for respawn:
        <%= for hero <- @heroes do %>
          <%= unless hero.coords do %>
            <div><%= hero.name %></div>
          <% end %>
        <% end %>
      </div>

      <div class="respawn-pool">
        Connected players:
        <%= for user <- @users do %>
          <div>
            <%= user.id <> ": " <> user.name %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def render_tile(assigns, x, y) do
    status = status_at_tile(assigns, x, y)

    ~L"""
    <div class="tile <%= status %>">
    </div>
    """
  end

  def mount(params, _session, socket) do
    game = Map.get(params, "game")
    name = Map.get(params, "name", generate_random_name())
    topic = Game.topic(game)

    # Subscribe to game updates
    Game.subscribe(game)

    # Subscribe to presence changes
    NightRPGWeb.Endpoint.subscribe(topic)

    # Track session with presence
    Presence.track(self(), topic, socket.id, %{name: name})

    # Get initial user state
    users = get_users(topic)

    # Connect to the game
    {:ok, _pid} = Game.connect(game)

    # Get initial game state
    {board, heroes} = Game.state(game)

    # TODO: this fixes an issue caused by mount being called twice.
    # Move name logic to a controller action to avoid
    Process.send_after(self(), :join, 10)

    {:ok,
      assign(socket,
        board: board,
        game: game,
        heroes: heroes,
        joined: false,
        name: name,
        users: users
      )}
  end

  def handle_info(:join, socket) do
    {:ok, _pid} = Game.join(socket.assigns.game, socket.assigns.name)
    Game.broadcast_update(socket.assigns.game)

    {:noreply, assign(socket, joined: true)}
  end

  def handle_info(:update, socket) do
    {board, heroes} = Game.state(socket.assigns.game)
    {:noreply, assign(socket, board: board, heroes: heroes)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    users = get_users(socket)
    {:noreply, assign(socket, users: users)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def handle_event("keyup", %{"code" => "Space"}, socket) do
    {:ok, pids} = Game.which_heroes(socket.assigns.game)

    hero =
      socket.assigns.heroes
      |> Enum.find(fn h -> h.name == socket.assigns.name end)

    Enum.each(pids, fn pid -> Hero.dodge(pid, hero.coords, hero.name) end)
    Game.broadcast_update(socket.assigns.game)

    {:noreply, socket}
  end

  def handle_event("keyup", %{"code" => code}, socket) do
    direction =
      case code do
        "ArrowLeft" -> :left
        "ArrowUp" -> :up
        "ArrowRight" -> :right
        "ArrowDown" -> :down
        _ -> nil
      end

    if direction do
      Hero.move(socket.assigns.game, socket.assigns.name, direction)
      Game.broadcast_update(socket.assigns.game)
    end

    {:noreply, socket}
  end

  def generate_random_name() do
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

  def get_users(%{assigns: %{game: game}}) do
    get_users("game:" <> game)
  end

  def get_users(topic) do
    topic
    |> Presence.list()
    |> Enum.map(fn {id, data} ->
      data
      |> Map.get(:metas, [%{}])
      |> List.first()
      |> Map.put(:id, id)
    end)
  end
end
