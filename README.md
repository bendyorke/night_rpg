# NightRPG

A small OTP based MMORPG, built per the requirements of Nightwatch.

## general structure

  * `GameRegistry` to register all games to
  * `GameSupervisor` to supervise a board and all heros
  * `Board` to validate player moves and respawn dead heroes
  * `Hero` to store position, life, request moves, attack, and listen for attacks

## mecahnics

  * simple browser based game
  * joining a game spawns a hero on a random tile with a random or given name
  * two players can control a character with the same name
  * players can navigate on walkable tiles but cannot pass through walls - there is no limit to number of players on a tile
  * players can attack other characters within one square - diagonally included
  * players attacks attack all emenys within range - 1 hit K.O.s
  * when you are dead you cannot perform any actions
  * every 5 seconds all dead heroes are removed and respawned when necessary

## implementation rules

  * each hero needs to store their state in a unqiue `GenServer`
  * websockets are not required
  * game should be loaded at `/game` or `/game?name=bendyorke`
  * player input can be buttons or keyboard

## dos

  * focus on clean code, software architecture, seperation of concerns, readable and testable code
  * provide production ready code: no TODOs, debug messages, buggy behavoir
  * utalize OTP: `GenServer`, `Supervisor`, and message passing should be used to your advantage
  * have tests for business logic and controller
  * use `phoenix`

## don'ts

  * focus on front-end code - the front-end should be as basic as possible
  * graphics, assets, and interactions - this is testing your web developer abilities, not game developer
  * libraries - vanilla elixir is better than many external libraries

## deliverables

  * github repository
  * instructions to run in development, tests, building (with elixir releases), and deploying
  * live production link

## development

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
