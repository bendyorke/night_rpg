# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :night_rpg,
  namespace: NightRPG,
  ecto_repos: [NightRPG.Repo]

# Configures the endpoint
config :night_rpg, NightRPGWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GeISrEmdtNhvYZq+m6zy3elR9J50bTAOaFR/pTnqepxiUsA4x8EgMOQyUC7psrQd",
  render_errors: [view: NightRPGWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: NightRPG.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
