defmodule Src.Db do

   @db %{
      player: %{
        1 => %{
          id: 1,
          name: "Nameless",
          age: nil,
          health: 99,
          mana: 212,
          money: 6208,
          team_id: 1
        },
        2 => %{
          id: 2,
          name: "Nameless",
          age: 34,
          health: 43,
          mana: 353,
          money: 8868,
          team_id: 1
        },
        3 => %{
          id: 3,
          name: "Nameless",
          age: 87,
          health: 41,
          mana: 272,
          money: 2169,
          team_id: 2
        },
        4 => %{
          id: 4,
          name: "Nameless",
          age: nil,
          health: 82,
          mana: 428,
          money: 5609,
          team_id: 2
        },
        5 => %{
          id: 5,
          name: "Nameless",
          age: 74,
          health: 4,
          mana: 307,
          money: 9502,
          team_id: 3
        },
        6 => %{
          id: 6,
          name: "Nameless",
          age: nil,
          health: 34,
          mana: 131,
          money: 2496,
          team_id: 3
        },
        7 => %{
          id: 7,
          name: "Nameless",
          age: nil,
          health: 84,
          mana: 324,
          money: 278,
          team_id: 4
        },
        8 => %{
          id: 8,
          name: "Nameless",
          age: 18,
          health: 2,
          mana: 184,
          money: 9545,
          team_id: 4
        },
        9 => %{
          id: 9,
          name: "Nameless",
          age: nil,
          health: 98,
          mana: 157,
          money: 6355,
          team_id: 5
        },
        10 => %{
          id: 10,
          name: "Nameless",
          age: 41,
          health: 73,
          mana: 94,
          money: 8853,
          team_id: 5
        },
        11 => %{
          id: 11,
          name: "񃣢",
          age: 75,
          health: 7,
          mana: 379,
          money: 9102,
          team_id: 6
        },
        12 => %{
          id: 12,
          name: "Nameless",
          age: 95,
          health: 99,
          mana: 460,
          money: 9616,
          team_id: 6
        }
      },
      battle_arena: %{
        1 => %{
          id: 1,
          name: "Ice Room"
        },
        2 => %{
          id: 2,
          name: "Candy Land"
        },
        3 => %{
          id: 3,
          name: "Fire Pit"
        }
      },
      team: %{
        1 => %{
          id: 1,
          name: "Nameless",
          location_id: 1
        },
        2 => %{
          id: 2,
          name: "Nameless",
          location_id: 1
        },
        3 => %{
          id: 3,
          name: "Nameless",
          location_id: 2
        },
        4 => %{
          id: 4,
          name: "Nameless",
          location_id: 2
        },
        5 => %{
          id: 5,
          name: "Nameless",
          location_id: 3
        },
        6 => %{
          id: 6,
          name: "Nameless",
          location_id: 3
        }
      },
      spell_type: %{
        1 => %{
          id: 1,
          name: "Heal",
          cost: 25,
          power: -10
        },
        2 => %{
          id: 2,
          name: "Fireball",
          cost: 85,
          power: 40
        },
        3 => %{
          id: 3,
          name: "Pew Pew",
          cost: 10,
          power: 15
        }
      },
      spell_instance: %{
        33 => %{
          id: 33,
          type_id: 3,
          player_id: 9
        },
        12 => %{
          id: 12,
          type_id: 1,
          player_id: 12
        },
        23 => %{
          id: 23,
          type_id: 2,
          player_id: 11
        },
        29 => %{
          id: 29,
          type_id: 3,
          player_id: 5
        },
        30 => %{
          id: 30,
          type_id: 3,
          player_id: 6
        },
        26 => %{
          id: 26,
          type_id: 3,
          player_id: 2
        },
        31 => %{
          id: 31,
          type_id: 3,
          player_id: 7
        },
        11 => %{
          id: 11,
          type_id: 1,
          player_id: 11
        },
        9 => %{
          id: 9,
          type_id: 1,
          player_id: 9
        },
        32 => %{
          id: 32,
          type_id: 3,
          player_id: 8
        },
        34 => %{
          id: 34,
          type_id: 3,
          player_id: 10
        },
        25 => %{
          id: 25,
          type_id: 3,
          player_id: 1
        },
        28 => %{
          id: 28,
          type_id: 3,
          player_id: 4
        },
        6 => %{
          id: 6,
          type_id: 1,
          player_id: 6
        },
        13 => %{
          id: 13,
          type_id: 2,
          player_id: 1
        },
        20 => %{
          id: 20,
          type_id: 2,
          player_id: 8
        },
        15 => %{
          id: 15,
          type_id: 2,
          player_id: 3
        },
        14 => %{
          id: 14,
          type_id: 2,
          player_id: 2
        },
        2 => %{
          id: 2,
          type_id: 1,
          player_id: 2
        },
        7 => %{
          id: 7,
          type_id: 1,
          player_id: 7
        },
        1 => %{
          id: 1,
          type_id: 1,
          player_id: 1
        },
        8 => %{
          id: 8,
          type_id: 1,
          player_id: 8
        },
        3 => %{
          id: 3,
          type_id: 1,
          player_id: 3
        },
        17 => %{
          id: 17,
          type_id: 2,
          player_id: 5
        },
        22 => %{
          id: 22,
          type_id: 2,
          player_id: 10
        },
        21 => %{
          id: 21,
          type_id: 2,
          player_id: 9
        },
        4 => %{
          id: 4,
          type_id: 1,
          player_id: 4
        },
        36 => %{
          id: 36,
          type_id: 3,
          player_id: 12
        },
        24 => %{
          id: 24,
          type_id: 2,
          player_id: 12
        },
        10 => %{
          id: 10,
          type_id: 1,
          player_id: 10
        },
        35 => %{
          id: 35,
          type_id: 3,
          player_id: 11
        },
        27 => %{
          id: 27,
          type_id: 3,
          player_id: 3
        },
        19 => %{
          id: 19,
          type_id: 2,
          player_id: 7
        },
        5 => %{
          id: 5,
          type_id: 1,
          player_id: 5
        },
        18 => %{
          id: 18,
          type_id: 2,
          player_id: 6
        },
        16 => %{
          id: 16,
          type_id: 2,
          player_id: 4
        }
      }

    }
  def db(), do: @db

  def battle(player_id) do
    Sorcery.Query.from_tk_map(Src.Queries.GetBattle, %{player_id: player_id}, @db)
  end
end


