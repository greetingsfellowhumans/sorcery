defmodule Sorcery.PortalServer.Ecto.MutationTest do
  use ExUnit.Case
  use Sorcery.GenServerHelpers
  import Sorcery.Setups
  alias Src.Queries.GetBattle
  alias Src.PortalServers.GenericClient, as: Client
  alias Sorcery.SorceryDb.Inspection
  alias Sorcery.Mutation, as: M

  setup [:demo_ecosystem]

  test "Ecto PortalServer can handle Mutations", _ctx do
    Src.PortalServers.Postgres.put_origin()
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
    
    assert_receive {:received_msg, {_pid, _msg, _old_state, state}}

    M.init(state.sorcery, portal_name)
    |> M.put([:player, args.player_id, :health], 100)
    |> M.update([:player, args.player_id, :health], fn _old_h, new_h -> new_h - 1 end)
    |> M.send_mutation()



    state = Client.get_state(pid)
    assert 99 == state.sorcery.portals.battle_portal.known_matches.data["?all_players"][1].health
  end

end
