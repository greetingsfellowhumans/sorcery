defmodule Sorcery.Query.BasicsTest do
  use ExUnit.Case
  #alias MyApp.Schemas.{Player, BattleArena, Team, SpellType, SpellInstance}
  alias Sorcery.ReturnedEntities, as: RE
  import Sorcery.Setups

  setup [:spawn_portal]

  test "A demo module gets some query goodies" do
    {:ok, pid} = GenServer.start_link(MyApp.PortalServers.Postgres, %{})
    msg = %{
      command: :run_query,
      from: self(),
      args: %{player_id: 1},
      query: MyApp.Queries.GetBattle,
    }
    send(pid, {:sorcery, msg})
    assert_receive {:sorcery, %{data: returned_entities}}
    assert is_struct(returned_entities, RE)
  end


  test "LiveViews also run queries", %{portal: _portal} do
    #dbg portal
  end

end
