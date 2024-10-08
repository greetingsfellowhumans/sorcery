defmodule Sorcery.Mutations.TempTest do
  use ExUnit.Case
  alias Sorcery.Mutation, as: M
  alias Sorcery.Query.ReverseQuery, as: RQ
  import Sorcery.Setups
  alias Sorcery.Mutation.Temp

  #setup [:spawn_portal, :teams_portal]


  # {{{ PreMutation operations should work
  test "PreMutation operations should work" do
    portal = spawn_portal()
    inner_state = Sorcery.PortalServer.InnerState.new(%{portals: %{the_battle: portal}})
    m = M.init(inner_state, :the_battle)
    m = M.update(m, [:player, 1, :health], fn _, age -> age - 10 end)
    assert 99 == inner_state.portals.the_battle.known_matches.data["?all_players"][1].health
    new_state = Temp.add_temp_portal(inner_state, m)
    assert 89 == new_state.portals.the_battle.temp_data["?all_players"][1].health

#
#    m = M.put(m, [:player, 1, :age], 10)
#    new_player2 = M.get(m, [:player, 1])
#    old_player2 = M.get_original(m, [:player, 1])
#    assert new_player2.age == 10
#    assert old_player2.age == old_player.age
#    m = M.update(m, [:player, 1, :age], fn _, age -> age * 2 end)
#    new_player3 = M.get(m, [:player, 1])
#    assert new_player3.age == 20
#
#    m = M.create_entity(m, :team, "?my_new_team", %{name: "My New Team"})
#    new_team = M.get(m, [:team, "?my_new_team"])
#    assert new_team.name == "My New Team"
#    m = M.delete_entity(m, :player, 1)
#    assert m.deletes.player == [1]
  end
  # }}}
#
#
#  # {{{ PreMutation should convert into a ParentMutation
#  test "PreMutation should convert into a ParentMutation", %{portal: portal, parent_pid: _parent} do
#    m = M.init(portal)
#    m = M.update(m, [:player, 1, :age], fn _, age -> age + 1 end)
#    m = M.create_entity(m, :team, "?my_team", %{name: "Hello!"})
#    m = M.delete_entity(m, :team, 5)
#    m = Sorcery.Mutation.ParentMutation.init(m)
#    assert m.updates.player[1] |> is_map()
#    assert m.inserts.team["?my_team"] == %{name: "Hello!"}
#    assert m.deletes.team == [5]
#  end
#  # }}}
#
#
#  # {{{ Parent can apply changes to store
#  test "Parent can apply changes to store", %{portal: portal, parent_pid: parent} do
#    m = M.init(portal)
#        |> M.put([:player, 1, :age], 25)
#        |> M.create_entity(:team, "?my_team", %{name: "Hello!"})
#
#    msg = %{
#      command: :mutation_to_parent,
#      from: self(),
#      args: %{mutation: m},
#    }
#    send(parent, {:sorcery, msg})
#    #assert_receive {:sorcery, %{args: %{mutation: m}} }
#    #team_id = m.inserts.team |> Map.keys() |> List.first()
#    #assert is_integer(team_id)
#
#  end
#  # }}}
#
#
#  # {{{ Should be able to generate diffs from ChildrenMutations
#  test "Should be able to generate diffs from ChildrenMutations", %{portal: portal, parent_pid: parent} do
#    #m = M.init(portal)
#    #    |> M.create_entity(:team, "?my_team", %{name: "Hello!"})
#
#    #msg = %{
#    #  command: :mutation_to_parent,
#    #  from: self(),
#    #  args: %{mutation: m},
#    #}
#    #send(parent, {:sorcery, msg})
#    #assert_receive {:sorcery, %{args: %{mutation: children_mutation}} }
#    #diff = M.Diff.new(children_mutation)
#
#    #[row] = diff.rows
#    #assert row.tk == :team 
#    #assert row.old_entity == nil
#
#    #assert RQ.diff_matches_portal?(diff, portal)
#  end
#  # }}}
#
#
end
