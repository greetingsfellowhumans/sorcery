defmodule Sorcery.Query.BasicReverseAlgoTest do
  use ExUnit.Case
  #alias Sorcery.Query.ReverseQueryAlgo, as: Algo


  #test "Filter Diff Rows by TK" do
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

  #  diff_row2 = %Sorcery.Mutation.DiffRow{
  #    tk: :player,
  #    id: 2,
  #    before: %{id: 2, name: "A"},
  #    after: %{id: 2, name: "B"},
  #    changed_keys: [:name]
  #  }
  #  diff = %Sorcery.Mutation.Diff{tks_affected: MapSet.new([:battle_arena]), rows: [diff_row1, diff_row2]}
  #  assert [diff_row1] == Algo.filter_diff_rows_by_tk(diff, :battle_arena)
  #  #refute RQ.diff_matches_query?(portal, diff2)
  #  assert Algo.diff_row_passes_clauses?(diff_row1, portal.reverse_query.clauses, portal.known_lvar_values)

  #end



end
