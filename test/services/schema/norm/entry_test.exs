defmodule Sorcery.Schema.Norm.EntryTest do
  use ExUnit.Case
  alias Sorcery.Schema, as: S
  alias Src.Schemas.Player, as: Player
  import Norm

  doctest S
  
  test "Schema module gets some goodies added" do
    demo_player = Player.gen_one( %{name: "Jose Valim", age: 25, team_id: 123} )
    #dbg player_spec
    assert conform!(demo_player, Player.t())
  end

end

