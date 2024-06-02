defmodule Sorcery.Query.BasicsTest do
  use ExUnit.Case
  alias Src.Queries.GetBattle
  doctest Sorcery.Query
  alias Src.Schemas.{Player, BattleArena, Team, SpellType, SpellInstance}
#  alias Sorcery.ReturnedEntities, as: RE
#  import Sorcery.Setups


  #setup [:spawn_portal]

  test "A demo query module fulfills behaviour interface" do
    clauses = GetBattle.clauses(%{player_id: 1})
    assert Enum.all?(clauses, fn c -> is_struct(c, Sorcery.Query.WhereClause) end)
    assert is_struct(GetBattle.raw_struct(), Sorcery.Query)

    tk_map = Src.Db.db()
    results = Sorcery.Query.from_tk_map(GetBattle, %{player_id: 1}, tk_map)
    player1 = results["?all_players"][1]
    assert %{health: 99} = player1
  end



end
