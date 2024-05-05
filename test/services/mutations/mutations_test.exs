defmodule Sorcery.Mutations.MutationsTest do
  use ExUnit.Case
  alias Sorcery.Mutation, as: M
  import Sorcery.Setups

  setup [:spawn_portal]


  # {{{ PreMutation operations should work
  test "PreMutation operations should work", %{portal: portal} do
    m = M.init(portal)
    m = M.update(m, [:player, 1, :age], fn _, age -> age + 1 end)
    new_player = M.get(m, [:player, 1])
    old_player = M.get_original(m, [:player, 1])
    assert new_player.age == 1 + old_player.age

    m = M.put(m, [:player, 1, :age], 10)
    new_player2 = M.get(m, [:player, 1])
    old_player2 = M.get_original(m, [:player, 1])
    assert new_player2.age == 10
    assert old_player2.age == old_player.age
    m = M.update(m, [:player, 1, :age], fn _, age -> age * 2 end)
    new_player3 = M.get(m, [:player, 1])
    assert new_player3.age == 20

    m = M.create_entity(m, :team, "?my_new_team", %{name: "My New Team"})
    new_team = M.get(m, [:team, "?my_new_team"])
    assert new_team.name == "My New Team"
    m = M.delete_entity(m, :player, 1)
    assert m.deletes.player == [1]
  end
  # }}}


  # {{{ PreMutation should convert into a ParentMutation
  test "PreMutation should convert into a ParentMutation", %{portal: portal, parent_pid: _parent} do
    m = M.init(portal)
    m = M.update(m, [:player, 1, :age], fn _, age -> age + 1 end)
    m = M.create_entity(m, :team, "?my_team", %{name: "Hello!"})
    m = M.delete_entity(m, :team, 5)
    m = Sorcery.Mutation.ParentMutation.init(m)
    assert m.updates.player[1] |> is_map()
    assert m.inserts.team["?my_team"] == %{name: "Hello!"}
    assert m.deletes.team == [5]
  end
  # }}}


  test "Parent can apply changes to store", %{portal: portal, parent_pid: parent} do
    m = M.init(portal)
        |> M.put([:player, 1, :age], 25)
        |> M.create_entity(:team, "?my_team", %{name: "Hello!"})

    msg = %{
      command: :mutation_to_parent,
      from: self(),
      args: %{mutation: m},
    }
    send(parent, {:sorcery, msg})
    assert_receive {:sorcery, %{args: %{mutation: m}} }

    team_id = m.inserts.team |> Map.keys() |> List.first()
    assert is_integer(team_id)
  end


  test "Parent can delete entities", %{portal: portal, parent_pid: parent} do
    [team | _] = Sorcery.Repo.all(MyApp.Schemas.Team)
                 |> Enum.sort_by(&(&1.id), :desc)
    m = M.init(portal)
        |> M.put([:player, 1, :age], 24)
        |> M.delete_entity(:team, team.id)

    msg = %{
      command: :mutation_to_parent,
      from: self(),
      args: %{mutation: m},
    }
    [id] = m.deletes.team
    assert id == team.id
    send(parent, {:sorcery, msg})
    assert_receive {:sorcery, %{args: %{mutation: _m}} } 

    [next_team | _] = Sorcery.Repo.all(MyApp.Schemas.Team)
               |> Enum.sort_by(&(&1.id), :desc)
    assert next_team != team
    assert next_team.id != id
  end

  test "Generate Diff" do
  end

  test "Handle deleting entities" do
  end

  test "Use primary and secondary entities" do
  end

  test "Handle NEW entities" do
  end

  test "Can reference new entities" do
    # So we need to do inserts FIRST
    # Mutation.create_entity(tk, "?person1", %{})
    # and then later
    # Mutation.put_attr(tk, 42, :player_id, "?person1.id")
  end


  #test "Build a mutation_chain and generate a diff" do
  #  
  #  {:ok, pid} = GenServer.start_link(MyApp.PortalServers.Postgres, %{})
  #  msg = %{
  #    command: :spawn_portal,
  #    from: self(),
  #    args: %{player_id: 1, portal_name: :battle_portal},
  #    query: MyApp.Queries.GetBattle,
  #  }
  #  send(pid, {:sorcery, msg})
  #  assert_receive {:sorcery, %{args: %{portal: portal}}}
  #  args = %{player1_id: 1, player2_id: 2}
  #  spells = RE.get_entities(portal.known_matches, "?spells") |> Enum.filter(&(&1.player_id == args.player1_id))
  #  dbg spells

  #end


end

