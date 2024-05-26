defmodule Sorcery.SorceryDbTest do
#  use ExUnit.Case
#  alias Sorcery.Mutation, as: M
#  import Sorcery.Setups
#  import Sorcery.SorceryDb.MnesiaAdapter
#
#  setup [:spawn_portal, :teams_portal, :populate_sorcery_db]
#
#  test "SorceryDb can be populated via mutations", %{portal: portal} do
#    m = M.init(portal)
#        |> M.create_entity(:team, "?my_team", %{name: "Hello!", id: 953, location_id: 953})
#    data = %{
#      updates: %{},
#      inserts: %{team: %{953 => %{id: 953, name: "Hello!", location_id: 953}}},
#      deletes: %{}
#    }
#
#    m = Sorcery.Mutation.ChildrenMutation.init(m, data)
#    pid_portal = [%{
#      pid: self(),
#      args: %{player_id: 1},
#      portal_name: :get_teams,
#      query_module: MyApp.Queries.GetBattle
#    }]
#
#    MyApp.Sorcery.run_mutation(m, pid_portal, self())
#    assert_receive {:sorcery, %{command: :portal_merge} = msg}
#  end
#
#  # {{{ MnesiaAdapter.guard_in/2
#  test "MnesiaAdapter.guard_in/2" do
#    ops = [
#      #:op, li,        expected_results
#      {:==, [40],      [40]},
#      {:==, [15],      [15]},
#      {:!=, [-10, 15], [40]},
#      {:!=, [15],      [-10, 40]},
#      {:>,  [15],      [40]},
#      {:>=, [40],      [40]},
#      {:<,  [40],      [-10, 15]},
#      {:<=, [40],      [-10, 40, 15]},
#      {:in, [40],      [40]},
#    ]
#
#    for {op, li, expected} <- ops do
#      {:atomic, actual} = :mnesia.transaction(fn ->
#        head = {:spell_type, :_, :_, :"$55", :"$1"}
#        guards = [guard_in(op, :"$1", li)]
#        ret = [:"$1"]
#        :mnesia.select(:spell_type, [{ head, guards, ret} ])
#      end)
#      assert expected == actual
#    end
#  end
#  # }}}
#
#
end
