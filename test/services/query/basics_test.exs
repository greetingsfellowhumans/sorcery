defmodule Sorcery.Query.BasicsTest do
  use ExUnit.Case
  alias Sorcery.Query, as: SrcQL
  #alias MyApp.Schemas.{Player, BattleArena, Team, SpellType, SpellInstance}
  alias MyApp.Schemas.{BattleArena}
  import SrcQL
  doctest SrcQL
  alias Sorcery.ReturnedEntities, as: RE


  test "A demo module gets some query goodies" do
    {:ok, pid} = GenServer.start_link(MyApp.PortalServers.Postgres, %{})
    msg = %{
      command: :run_query,
      from: self(),
      args: %{arena_id: 1},
      query: MyApp.Queries.GetArena,
    }
    send(pid, {:sorcery, msg})
    assert_receive returned_entities
    assert is_struct(returned_entities, RE)
  end


end
