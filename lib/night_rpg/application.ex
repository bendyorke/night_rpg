defmodule NightRPG.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      NightRPG.Repo,
      # Start the endpoint when the application starts
      NightRPGWeb.Endpoint,
      # Starts a worker by calling: NightRPG.Worker.start_link(arg)
      # {NightRPG.Worker, arg},
      {Registry, keys: :unique, name: :games},
      {Registry, keys: :unique, name: :heroes},
      {DynamicSupervisor, strategy: :one_for_one, name: NightRPG.GamesSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NightRPG.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NightRPGWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
