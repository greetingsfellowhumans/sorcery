defmodule Sorcery.Query.BasicReverseTest do
  use ExUnit.Case
  #alias Sorcery.Query, as: SrcQL
  ##alias MyApp.Schemas.{Player, BattleArena, Team, SpellType, SpellInstance}
  #alias MyApp.Schemas.{BattleArena}
  #alias MyApp.Queries.{GetArena}
  #import SrcQL
  #doctest SrcQL
  #alias Sorcery.ReturnedEntities, as: RE
  #alias Sorcery.Query.ReverseQuery, as: RQ
  #alias Sorcery.Query.ResultsLog, as: RLog


  #test "A demo module gets some query goodies" do
  #  {:ok, pid} = GenServer.start_link(MyApp.PortalServers.Postgres, %{})
  #  msg = %{
  #    command: :spawn_portal,
  #    from: self(),
  #    args: %{arena_id: 1},
  #    query: MyApp.Queries.GetArena,
  #  }
  #  send(pid, {:sorcery, msg})
  #  assert_receive portal

  #  diff_row1 = %Sorcery.Mutation.DiffRow{
  #    tk: :battle_arena,
  #    id: 1,
  #    before: %{id: 1, name: "A"},
  #    after: %{id: 1, name: "B"},
  #    changed_keys: [:name]
  #  }
  #  diff1 = %Sorcery.Mutation.Diff{tks_affected: MapSet.new([:battle_arena]), rows: [diff_row1]}
  #  assert RQ.diff_matches_query?(portal, diff1)


  #  diff_row2 = %Sorcery.Mutation.DiffRow{
  #    tk: :battle_arena,
  #    id: 2,
  #    before: %{id: 2, name: "A"},
  #    after: %{id: 2, name: "B"},
  #    changed_keys: [:name]
  #  }
  #  diff2 = %Sorcery.Mutation.Diff{tks_affected: MapSet.new([:battle_arena]), rows: [diff_row1]}

  #  #refute RQ.diff_matches_query?(portal, diff2)
  #end



end