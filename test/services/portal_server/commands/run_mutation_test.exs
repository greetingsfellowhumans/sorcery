#defmodule Sorcery.PortalServer.Commands.RunMutationTest do
#  use ExUnit.Case
#  alias Sorcery.PortalServer.Portal
#  alias Sorcery.Mutation, as: M
#  alias M.{ParentMutation, ChildrenMutation}
#  import Sorcery.Setups
#
#  setup [:commands_setup]
#
#  test "Should handle the RunMutation cmd", %{parent_pid: parent, child_state: state} do
#    portal = state.sorcery.portals.the_battle
#    player11 = portal.known_matches.data["?all_players"][11]
#
#
#    mutation = M.init(portal)
#               |> M.update([:player, 11, :health], fn _old, new -> new + 10 end)
#               |> M.create_entity(:spell_instance, "?my_spell", %{player_id: 11, type_id: 1})
#
#
#
#    msg = %{
#      command: :run_mutation,
#      mutation: mutation,
#      portal_name: :the_battle,
#      portal: portal
#    }
#
#    send(parent, {:sorcery, msg})
#
#    assert_receive {:sorcery, msg}
#    assert msg.command == :portal_merge
#
#  end
#
#end
