defmodule Src.Queries.GetBattle do
  # This is my new favourite example query. It is its own stress test, and elegantly covers most use cases.

  use Sorcery.Query, %{
    find: %{
      #"?player" => :*,
      #"?team" => :*,
      "?arena" => :*,
      "?all_teams" => [:name, :location_id],
      "?all_players" => :*,
      "?spells" => :*,
      "?spell_types" => :*,
    },
    args: %{
      player_id: :integer
    },
    where: [
      [ "?player", :player, :id, :args_player_id],                    # We start here
      [ "?team", :team, :id, "?player.team_id"],                      # Get a parent
      [ "?arena", :battle_arena, :id, "?team.location_id"],           # Get a parent
      [ "?all_teams", :team, :location_id, "?arena.id"],              # Get ALL children

      [ "?all_players", :player, [                                    # Test multiline clauses
        {:team_id, "?all_teams.id"},                                  # Get ALL children, for each
        {:health, {:>, 0}},                                           # Test literal math operations
      ]],          

      [ "?spells", :spell_instance, :player_id, "?all_players.id"],   # Get ALL children, for each
      [ "?spell_types", :spell_type, :id, "?spells.type_id"],         # Get a different parent, for each
    ]
  }

end
