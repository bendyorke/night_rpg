defmodule NightRPGWeb.GameLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    Welcome to the live game
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
