defmodule Sorcery.Schema.Norm.EntryTest do
  use ExUnit.Case
  alias Sorcery.Schema, as: S
  alias MyApp.Schemas.Player, as: Player
  import Norm

  doctest S
  
  test "Schema module gets some goodies added" do
    demo_player = %{name: "Jose Valim", age: 25}
    #player_spec = Player.t()
    #dbg player_spec
    assert conform!(demo_player, Player.t())

    demo_player = %{age: 18, name: nil}
    assert conform!(demo_player, Player.t())
  end

end

