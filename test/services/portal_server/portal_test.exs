defmodule Sorcery.PortalServer.PortalTest do
  use ExUnit.Case
  alias Sorcery.PortalServer.Portal, as: Portal
  import Sorcery.Helpers.Maps
#  doctest Portal
#  import Sorcery.Setups
#
#  setup [:spawn_portal]
#
  test "Portals" do
    portal = %Sorcery.PortalServer.Portal{
      query_module: Src.Queries.GetBattle,
      updated_at: ~T[17:50:11.697061],
      portal_name: :battle_portal,
      child_pid: self(),
      parent_pid: self(),
      args: %{player_id: 1},
      known_matches: %Sorcery.ReturnedEntities{
        primary_entities: [],
        lvar_tks: %{
          "?all_players" => :player,
          "?all_teams" => :team,
          "?arena" => :battle_arena,
          "?player" => :player,
          "?spell_types" => :spell_type,
          "?spells" => :spell_instance,
          "?team" => :team
        },
        data: %{
          "?all_players" => %{
            1 => %{
              id: 1,
              name: "Nameless",
              a_list: [-2854],
              age: nil,
              health: 99,
              mana: 149,
              money: 7327,
              team_id: 1
            },
          },
          "?all_teams" => %{
            1 => %{id: 1, name: "Nameless", location_id: 1},
          },
          "?arena" => %{1 => %{id: 1, name: "Ice Room"}},
          "?player" => %{
            1 => %{
              id: 1,
              name: "Nameless",
              a_list: [-2854],
              age: nil,
              health: 99,
              mana: 149,
              money: 7327,
              team_id: 1
            }
          },
          "?spell_types" => %{
            1 => %{id: 1, name: "Heal", coin_flip: nil, cost: 25, power: -10},
            2 => %{id: 2, name: "Fireball", coin_flip: nil, cost: 85, power: 40},
            3 => %{id: 3, name: "Pew Pew", coin_flip: nil, cost: 10, power: 15}
          },
          "?spells" => %{
            1 => %{id: 1, player_id: 1, type_id: 1},
            2 => %{id: 2, player_id: 2, type_id: 1},
            3 => %{id: 3, player_id: 3, type_id: 1},
            4 => %{id: 4, player_id: 4, type_id: 1},
            13 => %{id: 13, player_id: 1, type_id: 2},
            14 => %{id: 14, player_id: 2, type_id: 2},
            15 => %{id: 15, player_id: 3, type_id: 2},
            16 => %{id: 16, player_id: 4, type_id: 2},
            25 => %{id: 25, player_id: 1, type_id: 3},
            26 => %{id: 26, player_id: 2, type_id: 3},
            27 => %{id: 27, player_id: 3, type_id: 3},
            28 => %{id: 28, player_id: 4, type_id: 3}
          },
          "?team" => %{1 => %{id: 1, name: "Nameless", location_id: 1}}
        }
      },
      temp_data: %{}
    }
    frozen_portal = Portal.freeze(portal)
    assert portal.known_matches.data["?arena"] == frozen_portal.known_matches.data.battle_arena
    assert 12 == Enum.count(frozen_portal.known_matches.data.spell_instance)

    # Make sure it handles empty results
    portal = put_in_p(portal, [:known_matches, :data, "?spells"], %{})
    frozen_portal = Portal.freeze(portal)
    assert portal.known_matches.data["?arena"] == frozen_portal.known_matches.data.battle_arena
    assert 0 == Enum.count(frozen_portal.known_matches.data.spell_instance)

  end


end
