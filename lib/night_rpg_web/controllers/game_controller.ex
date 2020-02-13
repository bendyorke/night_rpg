defmodule NightRPGWeb.GameController do
  use NightRPGWeb, :controller

  def show(conn, %{"name" => name}) do
    # look up
    render(conn, "show.html", name: name)
  end
end
