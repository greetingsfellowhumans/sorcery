defmodule Player do
  @moduledoc false

  require Sorcery.SpecDb

  #use Norm

  @spec_table %{
    user_id: %{t: :id, require_update: false},
    name: %{t: :string, default: "Player", min: 3, max: 45},
    age: %{t: :integer, min: 0, max: 200, bump: true}
  }

  Sorcery.SpecDb.build_schema_module("player")
  # Alternately:
  #
  # Sorcery.SpecDb.build_ecto_schema("player")
  # Sorcery.SpecDb.build_norm_schema()
  # Sorcery.SpecDb.build_streamdata_generator("player")


end


defmodule Sorcery.SpecDb.SpecDbTest do
  use ExUnit.Case
  use ExUnitProperties
  use Norm


  test "build_schema macro" do
    # Builds the struct via Ecto
    assert Map.get(%Player{}, :name) == "Player"

    # Builds the Norm schema
    assert !valid?(%{name: "hello"}, Player.t())
    assert valid?(%Player{user_id: 1, age: 23, name: "hello"}, Player.t())
    assert valid?(%{user_id: 1, age: 23, name: "hello"}, Player.t())
  end

  property "Generates Players" do
    check all player <- Player.gen(%{user_id: 24}) do
      assert valid?(player, Player.t())

      # Valid changesets exist?
      assert [:user_id, :name, :age] == Sorcery.SpecDb.CsHelpers.get_cast_update(Player.spec_table())
      assert [:user_id, :name, :age] == Sorcery.SpecDb.CsHelpers.get_cast_insert(Player.spec_table())
      assert [:name, :age]           == Sorcery.SpecDb.CsHelpers.get_require_update(Player.spec_table())
      assert [:user_id, :name, :age] == Sorcery.SpecDb.CsHelpers.get_require_insert(Player.spec_table())

      cs = Player.sorcery_update(%Player{id: player.id}, player)
      assert cs.valid?

      player = Map.put(player, :age, 9999999)
      assert player.age != 200
      cs = Player.sorcery_update(%Player{id: player.id}, player)
      assert cs.valid?
      assert cs.changes.age == 200
    end
  end



end
