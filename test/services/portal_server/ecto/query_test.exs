defmodule Sorcery.PortalServer.Ecto.QueryTest do
  use ExUnit.Case
  use Sorcery.GenServerHelpers
  import Sorcery.Setups
  import Sorcery.Helpers.Maps
  alias Src.Queries.MultiJoin
  alias Src.Queries.GetBattle
  alias Src.PortalServers.GenericClient, as: Client
  alias Sorcery.SorceryDb.Inspection

  setup [:demo_ecosystem]

  test "Ecto PortalServer can handle SrcQL queries", _ctx do
    portal_name = :battle_portal
    args = %{player_id: 1}

    pid = spawn_client([
      %{
      portal_server: Postgres, 
      portal_name: portal_name,
      query_module: GetBattle,
      query_args: args
      }
    ])

    assert_receive {:received_msg, {_pid, msg, _old_state, new_sorcery}}
    assert :portal_merge == msg.command
    portal = new_sorcery.portals[portal_name]
    players_table = portal.known_matches.data["?all_players"]
    assert Map.has_key?(players_table, args.player_id)

    #expected = [%{id: 1, location_id: 1}]
    #assert expected == portal_view(inner_state, portal_name, "?team")
    #assert expected == Map.values(portal.known_matches.data["?team"])
    #assert inner_state == Client.get_state(pid).sorcery

    ### SorceryDb should now have an entry for the query
    #expected = [pid, Src.Queries.GetBattle, args]
    #assert expected in Inspection.get_all_portal_instances(portal_name)
  end



  test "Should handle multiple where clauses on joined tables" do
# {{{ sorcery
  src = %Sorcery.PortalServer.InnerState{
  config_module: Src,
  store_adapter: Sorcery.StoreAdapter.Ecto,
  pending_portals: [:kennel_portal, :player_portal, :kennel_portal,
   :player_portal],
  args: %{repo_module: Sorcery.Repo},
  portals: %{}
}
# }}}

    # {{{ wheres
    wheres = [
      %Sorcery.Query.WhereClause{
        lvar: :"?player",
        tk: :player,
        attr: :id,
        left: nil,
        right: 1,
        op: :==,
        other_lvar: nil,
        other_lvar_attr: nil,
        arg_name: nil,
        right_type: :literal
      },
      %Sorcery.Query.WhereClause{
        lvar: :"?spell_instances",
        tk: :spell_instance,
        attr: :player_id,
        left: nil,
        right: "?player.id",
        op: :==,
        other_lvar: :"?player",
        other_lvar_attr: :id,
        arg_name: nil,
        right_type: :lvar
      },
      %Sorcery.Query.WhereClause{
        lvar: :"?spell_instances",
        tk: :spell_instance,
        attr: :type_id,
        left: nil,
        right: 1,
        op: :==,
        other_lvar: nil,
        other_lvar_attr: nil,
        arg_name: nil,
        right_type: :literal
      },
    ]
    # }}}

# {{{ finds
  finds = %{
  "?player": [:id, :name, :age],
  "?team": [:id, :name, :location_id],
  "?spell_instances": [:id, :player_id, :type_id]
}
# }}}
 
    #{:ok, %{data: data}} = Sorcery.StoreAdapter.Ecto.Query.run_query(src, wheres, finds)
    #assert has_in_p(data, ["?player", 1])
    #assert has_in_p(data, ["?spell_instances", 1])

    # Now when the spell instance does not exist
    # {{{ wheres 2
    wheres = [
      %Sorcery.Query.WhereClause{
        lvar: :"?player",
        tk: :player,
        attr: :id,
        left: nil,
        right: 1,
        op: :==,
        other_lvar: nil,
        other_lvar_attr: nil,
        arg_name: nil,
        right_type: :literal
      },
      %Sorcery.Query.WhereClause{
        lvar: :"?spell_instances",
        tk: :spell_instance,
        attr: :player_id,
        left: nil,
        right: "?player.id",
        op: :==,
        other_lvar: :"?player",
        other_lvar_attr: :id,
        arg_name: nil,
        right_type: :lvar
      },
      %Sorcery.Query.WhereClause{
        lvar: :"?spell_instances",
        tk: :spell_instance,
        attr: :type_id,
        left: nil,
        right: 1,
        op: :>=,
        other_lvar: nil,
        other_lvar_attr: nil,
        arg_name: nil,
        right_type: :literal
      },
      %Sorcery.Query.WhereClause{
        lvar: :"?team",
        tk: :team,
        attr: :id,
        left: nil,
        right: 1,
        op: :==,
        other_lvar: nil,
        other_lvar_attr: nil,
        arg_name: nil,
        right_type: :literal
      },
    ]
    # }}}

    {:ok, %{data: data}} = Sorcery.StoreAdapter.Ecto.Query.run_query(src, wheres, finds)
    assert %{id: 1} = data["?player"][1]
    assert [1, 13, 25] == Map.keys(data["?spell_instances"])

  end


  # Since apparently the bug is not fixed. Trying it again with a hard coded query MultiJoin
#
#    where: [
#      [ "?player", :player, :id, :args_player_id],
#      [ "?spell_type", :spell_type, :power, 100],
#
#      [ "?spells", :spell_instance, [
#        {:player_id, "?player.id"},
#        {:type_id, "?spell_type.id"},
#      ]],          
#    ]
#  I think possibly the only way this works is that I start actually using subqueries.
#  Which was kinda already on the TODO list anyway...
#  But it is going to get extra gnarly.
#  I literally don't know how that would be possible.
#  almost like you need to query each lvar in isolation, in order.
#  which is even WORSE performance. 
#  
#  You *could* use Ecto.Multi.all(:"?lvar", query)
#  This is possibly the best you can hope for.
#  It actually might be better than what I have currently.
#  player_query = from(x in Player, where: x.id == ^arg, select: mandatory_fields)
#  st_query = from(x in SpellType, where: x.power == 100, select: mandatory_fields)
#  spell_query = from(x in SpellInstance, select: mandatory_fields)
#                |> where(x.player_id == ^multi[k])
#                |> where(x.type_id == ^multi[k])
#  M.all(:"?player", )
#  yaaaaa That might not work. It will scream when you pass in something like that. Maybe. Try it manually first
#
  # Currently getting:
  #** (Ecto.QueryError) unknown bind name `:"?player"` in query:
  #from s0 in Src.Schemas.SpellType,
  #  as: :"?spell_type",
  #  left_join: s1 in Src.Schemas.SpellInstance,
  #  as: :"?spells",
  #  on: nil,
  #  where: s0.power == ^100
#
#
#  Now it is creating a list of two threads:
#   [
#     [:"?spell_type", :"?spells"], 
#     [:"?player", :"?spells"]
#   ]

  test "Should handle the MultiJoin query", _ctx do
    #M.new()
    #|> M.all(:"?player", fn _ ->
    #  from(p in Src.Schemas.Player)
    #  |> where([p], p.id == 2)
    #end)
    #|> M.all(:"?spell_type", fn _ ->
    #  from(s in Src.Schemas.SpellType)
    #  |> where([s], s.power > 0)
    #end)
    #|> M.all(:"?spells", fn m ->
    #  player_ids = Enum.map(m[:"?player"], &(&1.id))
    #  type_ids = Enum.map(m[:"?spell_type"], &(&1.id))
    #  from(s in Src.Schemas.SpellInstance)
    #  |> where([s], s.player_id in ^player_ids)
    #  |> where([s], s.type_id in ^type_ids)
    #end)
    #|> dbg
    #|> Sorcery.Repo.transaction()
    #|> dbg
    portal_name = :multijoin
    args = %{player_id: 2}

    pid = spawn_client([
      %{
      portal_server: Postgres, 
      portal_name: portal_name,
      query_module: MultiJoin,
      query_args: args
      }
    ])

    assert_receive {:received_msg, {_pid, msg, _old_state, new_sorcery}}
    data = new_sorcery.portals.multijoin.known_matches.data
    #assert :portal_merge == msg.command
    #portal = new_sorcery.portals[portal_name]
    #players_table = portal.known_matches.data["?player"]
    #assert Map.has_key?(players_table, args.player_id)
    refute Enum.empty?(data["?player"])
    refute Enum.empty?(data["?spells"])

  end

  ### DELETE ME
  #defp handle_clause(q, clause, multi) do
  #  right = case clause.right_type do
  #    :lvar -> 
  #      Enum.map(multi[clause.right_type], &(&1[clause.right]))
  #    _ -> clause.right
  #  end
  #  where(q, [x], x[^clause.attr], ^clause.op, ^right)
  #end

end
