defmodule Sorcery.Schema.Generation.EntryTest do
  use ExUnit.Case
  alias Sorcery.Schema, as: S
  alias Src.Schemas.Player, as: Player

  doctest S
  
  test "Schema module gets some goodies added" do
    [demo_player] = Player.gen() |> Enum.take(1)
    #assert valid?(demo_player, Player.t())
    assert Map.has_key?(demo_player, :id)
    #demo_player = struct(Player, demo_player)
    [demo_player] = Player.gen(%{team_id: 42}) |> Enum.take(1)
    assert demo_player.team_id == 42

    # Can generate a specific id
    [demo_player] = Player.gen(%{id: 42}) |> Enum.take(1)
    assert demo_player.id == 42
  end

  #test "Generate ReturnedEntities" do
  #  re = Player.gen_re(2)
  #end
end

