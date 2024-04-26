defmodule Sorcery.Mutations.MutationsTest do
  use ExUnit.Case
  alias Sorcery.Mutation
  #alias MyApp.Queries.{GetBattle}
  #alias Sorcery.Query.ReverseQuery, as: RQ
  alias Sorcery.ReturnedEntities, as: RE
  #alias Sorcery.Mutation.{Diff, DiffRow}

  test "Freeze Portal" do
  end

  test "Mutation API" do
    # init(portal)
    # update_in(mutation, [tk, id, attr])
    # put_in(mutation, [tk, id, attr])
    # create_entity(tk, "?lvar", body)
    # delete_entity(tk, id)
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

