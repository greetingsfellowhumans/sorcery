defmodule Sorcery.Setups do
  use ExUnit.Case#, async: true


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
    assert_receive {:sorcery, %{args: %{portal: portal}, command: :spawn_portal_response} }
    ctx =
      ctx
      |> Map.put(:portal, portal)
      |> Map.put(:parent_pid, pid)
    {:ok, ctx}
  end
  # }}}


  # {{{ :teams_portal
  def teams_portal(ctx) do
    pid = ctx.parent_pid
    msg = %{
      command: :spawn_portal,
      from: self(),
      args: %{portal_name: :all_teams},
      query: MyApp.Queries.AllTeams,
    }
    send(pid, {:sorcery, msg})
    assert_receive {:sorcery, %{args: %{portal: portal}, command: :spawn_portal_response} }
    ctx =
      ctx
      |> Map.put(:teams_portal, portal)
    {:ok, ctx}
  end
  # }}}



  def live_view(%{db: db} = ctx) do
    {:ok, pid} = GenServer.start_link(MyApp.PortalServers.LiveView, %{db: db})
    ctx = Map.put(ctx, :live_view_pid, pid)
    {:ok, ctx}
  end

end
