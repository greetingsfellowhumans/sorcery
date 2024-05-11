defmodule Sorcery.StoreAdapter.InMemoryTest do
  use ExUnit.Case
#  alias Sorcery.ReturnedEntities, as: RE
#  import Sorcery.Setups
#
#  setup [:spawn_portal, :populate_in_memory, :live_view]
#
#  test "Test Query", %{db: db, live_view_pid: pid} do
#    msg = %{
#      command: :run_query,
#      from: self(),
#      args: %{},
#      query: MyApp.Queries.AllTeams,
#    }
#    send(pid, {:sorcery, msg})
#    assert_receive {:sorcery, boop }
#    dbg boop
#  end
#
#
#  test "LiveViews also run queries", %{portal: portal} do
#    #dbg portal
#  end

end
