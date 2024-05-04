defmodule Sorcery.Setups do
  use ExUnit.Case, async: true



  # {{{ :spawn_portal
  def spawn_portal(ctx) do
    {:ok, pid} = GenServer.start_link(MyApp.PortalServers.Postgres, %{})
    msg = %{
      command: :spawn_portal,
      from: self(),
      args: %{player_id: 1, portal_name: :battle_portal},
      query: MyApp.Queries.GetBattle,
    }
    send(pid, {:sorcery, msg})
    assert_receive {:sorcery, %{args: %{portal: portal}} }
    {:ok, %{portal: portal}}
  end
  # }}}


end
