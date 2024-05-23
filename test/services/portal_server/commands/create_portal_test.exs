defmodule Sorcery.PortalServer.Commands.CreatePortalTest do
  use ExUnit.Case
  alias Sorcery.PortalServer.Portal

  test "Should handle the CreatePortal cmd" do
    msg = %{
      command: :create_portal,
      child_pid: self(),
      portal_name: :the_battle,
      query_module: MyApp.Queries.GetBattle,
      args: %{player_id: 1}
    }

    {:ok, pid} = GenServer.start_link(MyApp.PortalServers.Postgres, %{})
    send(pid, {:sorcery, msg})
    assert_receive {:sorcery, msg}
    #%{command: :portal_merge, portal_name: name, data: data, timestamp: time} = msg
    #assert is_atom(name)

    #msg = %{portal_name: name, portal: portal}

    #new_state = Sorcery.PortalServer.Commands.PortalMerge.entry(msg, %{sorcery: %{}})
    #assert portal == new_state.sorcery.portals_to_parent[pid][name]
  end

end
