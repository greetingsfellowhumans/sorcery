defmodule Sorcery.Query.BasicsTest do
  use ExUnit.Case
  alias Src.Queries.GetBattle
  alias Src.Queries.MultiJoin
  doctest Sorcery.Query


  test "A demo query module fulfills behaviour interface" do
    clauses = GetBattle.clauses(%{player_id: 1})
    assert Enum.all?(clauses, fn c -> is_struct(c, Sorcery.Query.WhereClause) end)
    assert is_struct(GetBattle.raw_struct(), Sorcery.Query)

    tk_map = Src.Db.db()
    results = Sorcery.Query.from_tk_map(GetBattle, %{player_id: 1}, tk_map)
    player1 = results["?all_players"][1]
    assert %{health: 99} = player1
  end

  test "Should handle multiple joins in one LVAR" do
    clauses = MultiJoin.clauses(%{player_id: 1})
    assert Enum.all?(clauses, fn c -> is_struct(c, Sorcery.Query.WhereClause) end)
    assert is_struct(MultiJoin.raw_struct(), Sorcery.Query)

    #tk_map = Src.Db.db()
    tk_map = %{
      player: %{
        1 => %{id: 1}
      },
      spell_type: %{
        1 => %{id: 1, name: "Heal", power: -10, coin_flip: false, cost: 25},
        2 => %{id: 2, name: "Fireball", power: 40, coin_flip: true, cost: 85},
        3 => %{id: 3, name: "Pew Pew", power: 15, coin_flip: nil, cost: 10}
      },
      spell_instance: %{
        1 => %{id: 1, player_id: 1, type_id: 1},
        2 => %{id: 2, player_id: 1, type_id: 2},
        3 => %{id: 3, player_id: 2, type_id: 1},
        4 => %{id: 4, player_id: 2, type_id: 2},
      }
    }
    results = Sorcery.Query.from_tk_map(MultiJoin, %{player_id: 1}, tk_map)
    spells = results["?spells"] |> Map.keys() |> Enum.sort()
    assert [2] == spells
  end


end
