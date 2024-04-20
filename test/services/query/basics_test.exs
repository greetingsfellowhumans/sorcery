defmodule Sorcery.Query.BasicsTest do
  use ExUnit.Case
  alias Sorcery.Query, as: SrcQL
  #alias MyApp.Schemas.{Player, BattleArena, Team, SpellType, SpellInstance}
  alias MyApp.Schemas.{BattleArena}
  alias MyApp.Queries.{GetArena}
  import SrcQL
  doctest SrcQL
  alias Sorcery.ReturnedEntities, as: RE
  alias Sorcery.Query.ReverseQuery, as: RQ
  alias Sorcery.Query.ResultsLog, as: RLog


  test "A demo module gets some query goodies" do
    {:ok, pid} = GenServer.start_link(MyApp.PortalServers.Postgres, %{})
    msg = %{
      command: :run_query,
      from: self(),
      args: %{player_id: 1},
      query: MyApp.Queries.GetBattle,
    }
    send(pid, {:sorcery, msg})
    assert_receive returned_entities
    assert is_struct(returned_entities, RE)
    #dbg returned_entities

    #results_log = RLog.pairs_to_df(GetBattle.reverse_finds(), returned_entities)
    #dbg results_log
  end



end
