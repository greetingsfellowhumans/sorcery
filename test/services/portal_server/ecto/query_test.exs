defmodule Sorcery.PortalServer.Ecto.QueryTest do
  use ExUnit.Case
  use Sorcery.GenServerHelpers
  import Sorcery.Setups
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

    assert_receive {:received_msg, {_pid, _msg, _old_state, new_state}}
    client_src = new_state.sorcery 
    portal = client_src.portals.battle_portal
    expected = [%{id: 1, location_id: 1}]
    assert expected == portal_view(client_src, portal_name, "?team")
    assert expected == Map.values(portal.known_matches.data["?team"])
    assert client_src == Client.get_state(pid).sorcery

    ## SorceryDb should now have an entry for the query
    expected = [pid, Src.Queries.GetBattle, args]
    assert expected in Inspection.get_all_portal_instances(portal_name)
  end

end
