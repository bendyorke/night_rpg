defmodule NightRPGWeb.GameController do
  use NightRPGWeb, :controller

  def show(conn, params) do
    game = Map.get(params, "game")
    name = Map.get(params, "name", generate_random_name())

    live_render(conn, NightRPGWeb.GameLive, session: %{
      "game" => game,
      "name" => name,
    })
  end

  def generate_random_name() do
    ?a..?z
    |> Enum.take_random(8)
    |> List.to_string()
  end
end
