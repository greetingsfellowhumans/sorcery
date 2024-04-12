defmodule Sorcery.Schema.Generation.EntryTest do
  use ExUnit.Case
  alias Sorcery.Schema, as: S
  alias MyApp.Schemas.Player, as: Player
  use Norm

  doctest S
  
  test "Schema module gets some goodies added" do
    [demo_player] = Player.gen() |> Enum.take(1)
    #assert valid?(demo_player, Player.t())
    assert Map.has_key?(demo_player, :id)
  end

  test "Generate ReturnedEntities" do
    re = Player.gen_re(2)
    dbg re
  end
end

