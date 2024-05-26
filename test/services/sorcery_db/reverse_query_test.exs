#defmodule Sorcery.SorceryDb.ReverseQueryTest do
#  use ExUnit.Case
#  alias Sorcery.Query.WhereClause, as: Clause
#  alias Sorcery.SorceryDb.ReverseQuery, as: RQ
#  import Sorcery.Setups
#
#  setup [:rev_query_tables]
#
#
#
#  # {{{ test entity_matches_clause
#  test "Should determine whether an entity matches a :literal clause" do
#    clause = Clause.new(["?a", :player, :health, 10])
#    entity = %{id: 1, health: 10}
#    assert RQ.entity_matches_clause(entity, clause, %{})
#
#    entity = %{id: 1, health: 15}
#    refute RQ.entity_matches_clause(entity, clause, %{})
#
#    clause = Clause.new(["?a", :player, :health, {:<, 0}])
#    refute RQ.entity_matches_clause(entity, clause, %{})
#
#    clause = Clause.new(["?a", :player, :health, {:in, [15]}])
#    assert RQ.entity_matches_clause(entity, clause, %{})
#  end
#  test "Should determine whether an entity matches a :args clause" do
#    clause = Clause.new(["?a", :player, :health, :args_health])
#    entity = %{id: 1, health: 10}
#    assert RQ.entity_matches_clause(entity, clause, %{args: %{health: 10}})
#
#    clause = Clause.new(["?a", :player, :health, {:>=, :args_health}])
#    entity = %{id: 1, health: 5}
#    refute RQ.entity_matches_clause(entity, clause, %{args: %{health: 10}})
#
#    clause = Clause.new(["?a", :player, :health, {:in, :args_health}])
#    entity = %{id: 1, health: 5}
#    assert RQ.entity_matches_clause(entity, clause, %{args: %{health: 1..10}})
#  end
#
#  test "Should determine whether an entity matches a :lvar clause" do
#
#    clause = Clause.new(["?a", :player, :b_id, "?b.id"])
#    a = %{id: 1, b_id: 10}
#    b = %{id: 10}
#    assert RQ.entity_matches_clause(a, clause, %{right_entity: b})
#
#    a = %{id: 1, b_id: 20}
#    b = %{id: 10}
#    refute RQ.entity_matches_clause(a, clause, %{right_entity: b})
#
#    clause = Clause.new(["?a", :player, :b_id, {:>, "?b.id"}])
#    a = %{id: 1, b_id: 20}
#    b = %{id: 10}
#    assert RQ.entity_matches_clause(a, clause, %{right_entity: b})
#
#  end
#  # }}}
#
#  test "Get the correct list of portal_names" do
#    diff = struct(Sorcery.Mutation.Diff, %{tks_affected: [:battle_arena], rows: []})
#    assert RQ.get_portal_names_affected_by_diff(diff) == [:battle_room]
#    diff = struct(Sorcery.Mutation.Diff, %{tks_affected: [:player], rows: [
#      Sorcery.Mutation.DiffRow.new(%{
#        tk: :player,
#        id: 1,
#        old_entity: %{id: 1, health: 10, team_id: 1},
#        new_entity: %{id: 1, health: 50, team_id: 1},
#        changes: [{:health, 10, 50}]
#      })
#    ]})
#    assert RQ.get_portal_names_affected_by_diff(diff) == [:battle_room]
#
#    [ [player1, _mod, _args], _] = RQ.get_all_portal_instances(:battle_room)
#    assert Enum.count(RQ.get_all_portal_instances(:battle_room, exclude_pids: [player1])) == 1
#
#
#  end
#
#  test "Reverse query should work" do
#    diff = struct(Sorcery.Mutation.Diff, %{tks_affected: [:player], rows: [
#      Sorcery.Mutation.DiffRow.new(%{
#        tk: :player,
#        id: 1,
#        old_entity: %{id: 1, health: 10, team_id: 1},
#        new_entity: %{id: 1, health: 50, team_id: 1},
#        changes: [{:health, 10, 50}]
#      })
#    ]})
#    [{pid1, :battle_room}, {pid2, :battle_room}] = RQ.reverse_query(diff)
#    assert pid1 != pid2
#  end
#
#
#end
