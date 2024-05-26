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

    Client.spoof(pid, fn -> 
      M.init(state.sorcery, portal_name)
      |> M.put([:player, args.player_id, :health], 100)
      |> M.send_mutation()
    end)

    #assert_receive {:received_msg, {_pid, %{command: :portal_put}, _old_state, state}}
    #Process.sleep(200)
    #assert_receive {:received_msg, {_pid, msg, _old_state, state}}

    #portal_view(state.sorcery, portal_name, "?all_players")[args.player_id]
  end

end
