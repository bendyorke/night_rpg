defmodule NightRPGWeb.PageController do
  use NightRPGWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
