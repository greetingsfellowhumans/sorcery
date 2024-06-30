defmodule Sorcery.PortalServer.Ecto.QueryTest do
  use ExUnit.Case
  use Sorcery.GenServerHelpers
  import Sorcery.Setups
  import Sorcery.Helpers.Maps
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

    assert_receive {:received_msg, {_pid, _msg, _old_state, inner_state}}
    portal = inner_state.portals.battle_portal
    expected = [%{id: 1, location_id: 1}]
    assert expected == portal_view(inner_state, portal_name, "?team")
    assert expected == Map.values(portal.known_matches.data["?team"])
    assert inner_state == Client.get_state(pid).sorcery

    ## SorceryDb should now have an entry for the query
    expected = [pid, Src.Queries.GetBattle, args]
    assert expected in Inspection.get_all_portal_instances(portal_name)
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
  "?player": [:id, :name],
  "?spell_instances": [:id, :player_id, :type_id]
}
# }}}
 
    {:ok, %{data: data}} = Sorcery.StoreAdapter.Ecto.Query.run_query(src, wheres, finds)
    assert has_in_p(data, ["?player", 1])
    assert has_in_p(data, ["?spell_instances", 1])

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
        right: 99999999,
        op: :==,
        other_lvar: nil,
        other_lvar_attr: nil,
        arg_name: nil,
        right_type: :literal
      },
    ]
    # }}}
    {:ok, %{data: data}} = Sorcery.StoreAdapter.Ecto.Query.run_query(src, wheres, finds)
    assert has_in_p(data, ["?player", 1])
    refute has_in_p(data, ["?spell_instances", 1])
  end

end
