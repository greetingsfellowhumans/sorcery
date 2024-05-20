defmodule Sorcery.Setups do
  use ExUnit.Case#, async: true
  alias MyApp.Sorcery.Schemas.{Player, BattleArena, Team, SpellType, SpellInstance}
  import Sorcery.Helpers.Names
  import Sorcery.Helpers.Maps
  alias Sorcery.Query.WhereClause, as: Clause
  alias Sorcery.SorceryDb.ReverseQuery, as: RQ

  # {{{ :populate_sorcery_db
  def populate_sorcery_db(ctx) do
    all_schemas = [Player, BattleArena, Team, SpellType, SpellInstance]
    m = Enum.reduce(all_schemas, %{inserts: %{}, updates: %{}, deletes: %{}}, fn schema, acc ->
      tk = mod_to_tk(schema)

      entities = Sorcery.Repo.all(schema)
      Enum.reduce(entities, acc, fn entity, acc ->
        put_in_p(acc, [:updates, tk, entity.id], entity)
      end)

    end)

    MyApp.Sorcery.run_mutation(m, %{}, self())

    {:ok, ctx}
  end
  # }}}


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


  # {{{ :live_view
  def live_view(%{db: db} = ctx) do
    {:ok, pid} = GenServer.start_link(MyApp.PortalServers.LiveView, %{db: db})
    ctx = Map.put(ctx, :live_view_pid, pid)
    {:ok, ctx}
  end
  # }}}


  def rev_query_tables(ctx) do
    ###
    # Suppose there is a battle happening between players 1 and 2, while player 3 is looking at a list of teams
    ####

    arenas = [
      %{id: 1},
      %{id: 2},
    ]
    teams = [
      %{id: 1, location_id: 1, name: "teama", x: "a"},
      %{id: 2, location_id: 1, name: "teamb", x: "b"},
      %{id: 3, location_id: 2, name: "teamc", x: "c"},
    ]
    players = [
      %{id: 1, health: 10, team_id: 1},
      %{id: 2, health: 100, team_id: 2},
      %{id: 3, health: 30, team_id: 3},
    ]



    ctx1 = %{
      pid: spawn(fn -> nil end),
      args: %{player_id: 1},
      page: :battle_room,
      query_mod: MyApp.Queries.GetBattle,
      player: Enum.filter(players, &(&1.id == 1)),
      all_players: Enum.filter(players, &(&1.id in [1, 2])),
      team: Enum.filter(teams, &(&1.id == 1)),
      all_teams: Enum.filter(teams, &(&1.id in [1, 2])),
      arenas: Enum.filter(arenas, &(&1.id == 1)),
    }
    ctx2 = %{
      pid: spawn(fn -> nil end),
      args: %{player_id: 2},
      page: :battle_room,
      query_mod: MyApp.Queries.GetBattle,
      player: Enum.filter(players, &(&1.id == 2)),
      all_players: Enum.filter(players, &(&1.id in [1, 2])),
      team: Enum.filter(teams, &(&1.id == 2)),
      all_teams: Enum.filter(teams, &(&1.id in [1, 2])),
      arenas: Enum.filter(arenas, &(&1.id == 1)),
    }
    ctx3 = %{
      pid: spawn(fn -> nil end),
      args: %{},
      page: :list_teams,
      query_mod: MyApp.Queries.AllTeams,
      players: [],
      teams: teams,
      arenas: []
    }

    for ctx <- [ctx1, ctx2, ctx3] do
      RQ.put_portal_table(ctx.page, ctx.pid, ctx.query_mod, ctx.args)
      case ctx.page do
        :battle_room ->
          RQ.repopulate_watcher_table(ctx.page, :"?player", ctx.pid, ctx.player)
          RQ.repopulate_watcher_table(ctx.page, :"?all_player", ctx.pid, ctx.all_players)
          RQ.repopulate_watcher_table(ctx.page, :"?team", ctx.pid, ctx.team)
          RQ.repopulate_watcher_table(ctx.page, :"?all_teams", ctx.pid, ctx.all_teams)
          RQ.repopulate_watcher_table(ctx.page, :"?arena", ctx.pid, ctx.arenas)
        :list_teams ->
          RQ.repopulate_watcher_table(ctx.page, :"?all_teams", ctx.pid, ctx.teams)
      end
    end



    {:ok, ctx}
  end

end
