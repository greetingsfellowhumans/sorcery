defmodule Sorcery.Schema.Db.EntryTest do
  use ExUnit.Case
  alias MyApp.Sorcery.Schemas.Player, as: Player

  
  test "Schemas can run a query" do
    #{:ok, pid} = GenServer.start_link(Player, %{})
    #demo_player = Player.run_mutation(pid, %{})
  end

end

