defmodule Sorcery.PortalServer.PortalTest do
  use ExUnit.Case
  alias Sorcery.PortalServer.Portal, as: Portal
  doctest Portal
  alias Sorcery.ReturnedEntities, as: RE


  test "Portals" do
    matches = %{
      lvar_tks: %{
        "?all_players" => :player,
        "?arena" => :battle_arena,
        "?player" => :player,
      }, 
      data: %{
        "?all_players" => %{
          1 => %{
            id: 1,
            name: "Nameless",
            team_id: 1,
            health: 31,
            age: 70,
            mana: 202,
            money: 9271
          },
          2 => %{
            id: 2,
            name: "报",
            team_id: 1,
            health: 22,
            age: 73,
            mana: 341,
            money: 5941
          },
        },
        "?arena" => %{1 => %{id: 1, name: "Ice Room"}},
        "?player" => %{1 => %{id: 1, team_id: 1}},
      }}
    portal = Portal.new(%{known_matches: matches})
    frozen_portal = Portal.freeze(portal)
    assert portal.known_matches.data["?arena"] == frozen_portal.known_matches.data.battle_arena

    players = Map.merge(
      portal.known_matches.data["?player"],
      portal.known_matches.data["?all_players"]
    )
    assert portal.known_matches.data["?arena"] == frozen_portal.known_matches.data.battle_arena
    assert players == frozen_portal.known_matches.data.player
  end



end

