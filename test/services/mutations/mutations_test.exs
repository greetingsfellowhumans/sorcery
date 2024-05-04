defmodule Sorcery.Mutations.MutationsTest do
  use ExUnit.Case
  alias Sorcery.Mutation, as: M
  import Sorcery.Setups

  setup [:spawn_portal]


  test "PreMutation operations", %{portal: portal} do
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
    refute Map.has_key?(m.new_data.player, 1)
  end



  test "Mutation CMD" do
    # Can send to Portal Server. 
    # PS can receive.
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

