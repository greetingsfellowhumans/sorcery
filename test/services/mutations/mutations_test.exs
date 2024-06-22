defmodule Sorcery.Mutations.MutationsTest do
  use ExUnit.Case
  alias Sorcery.Mutation, as: M
#  alias Sorcery.Query.ReverseQuery, as: RQ
#  import Sorcery.Setups
#
#  setup [:spawn_portal, :teams_portal]

  # {{{ temp_portals for optimistic updates
  test "Mutations create a temp_portal" do
    parent = spawn(fn -> nil end)
    battle = Src.Db.battle(1)
    portal = Sorcery.PortalServer.Portal.new(%{
      query_module: Src.Queries.GetBattle,
      portal_name: :battle,
      parent_pid: parent,
      child_pid: self(),
      args: %{player_id: 1},
      known_matches: %{
        lvar_tks: Src.Queries.GetBattle.raw_struct().lvar_tks |> Enum.into(%{}),
        data: battle
      }
    })

    outer_state = %{
      sorcery: Sorcery.PortalServer.InnerState.new(%{
        portals: %{battle: portal}
      })
    }

    {:ok, inner_state} = 
      M.init(outer_state.sorcery, :battle)
      |> M.update([:player, 1, :health], fn _, h -> h - 1 end)
      |> M.send_mutation(outer_state.sorcery)

    assert inner_state.portals.battle.temp_data["?all_players"][1].health < battle["?all_players"][1].health
  end
  # }}}


  # {{{ PreMutation operations should work
  test "PreMutation operations should work" do
    outer_state = Sorcery.Setups.demo_state(%{})

    M.init(outer_state.sorcery, :the_battle)
    |> M.create_entity(:team, "?new_team", %{name: "I am a new team!", location_id: 1})
    #|> M.create_entity(:team, "?enemy_team", %{name: "I am a bad team!", location_id: "?new_team.id"})
    |> M.send_mutation(outer_state.sorcery)


    assert_receive {:sorcery, %{command: :portal_put, data: data}}
    new_team = data["?all_teams"] |> Enum.find_value(fn 
      {_, %{name: "I am a new team!"} = entity} -> entity
      _ -> false
    end)
    assert is_integer(new_team.id)

    Sorcery.Repo.get_by(Src.Schemas.Team, [location_id: new_team.id])
  end

  test "ordering inserts" do
    inserts = %{
      dog: %{
        "?my_dog" => %{id: "?my_dog", team_id: "?enemy_team.id"},
      },
      team: %{
        "?enemy_team" => %{
          id: "?enemy_team",
          name: "I am a bad team!",
          location_id: "?new_team.id"
        },
        "?new_team" => %{id: "?new_team", name: "I am a new team!", location_id: 1}
      },
    }
    assert [{:team, "?new_team"}, {:team, "?enemy_team"}, {:dog, "?my_dog"}] = Sorcery.StoreAdapter.Ecto.Mutation.insert_order(inserts)
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
