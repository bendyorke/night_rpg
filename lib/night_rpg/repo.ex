defmodule NightRPG.Repo do
  use Ecto.Repo,
    otp_app: :night_rpg,
    adapter: Ecto.Adapters.Postgres
end
