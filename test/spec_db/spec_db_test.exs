defmodule Player do
  @moduledoc false

  require Sorcery.SpecDb

  @spec_table %{
    user_id: %{t: :id, require_update: true},
    name: %{t: :string, default: "Player", min: 3, max: 45},
    age: %{t: :integer, min: 0, max: 200, bump: true},
    gender: %{t: :string, one_of: ["male", "female"]},
    permissions: %{t: :list, coll_of: :string},
    gene: %{t: :list, coll_of: :trinary, length: 5},
    colors: %{t: :list, coll_of: ["red", "blue", "green"], min: 2, max: 5},
    opt: %{t: :id, required: false},
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
    assert valid?(%Player{user_id: 1, opt: 1, permissions: ["admin"], gene: [true, false, nil, nil, nil], gender: "male", age: 23, name: "hello", colors: ["red", "green"]}, Player.t())
    assert valid?(%{user_id: 1, opt: 1, permissions: ["admin"], gene: [true, false, nil, nil, nil], gender: "male", age: 23, name: "hello", colors: ["blue", "green"]}, Player.t())
  end

  property "Generates Players" do
    check all player <- Player.gen(%{user_id: 24}) do
      assert valid?(player, Player.t())

      col_count = Enum.count(player.colors)
      assert col_count >= 2 and col_count <= 8

      # Valid changesets exist?
      assert [:user_id, :permissions, :opt, :name, :gene, :gender, :colors, :age] 
        == Sorcery.SpecDb.CsHelpers.get_cast_update(Player.spec_table())

      assert [:user_id, :permissions, :opt, :name, :gene, :gender, :colors, :age] 
        == Sorcery.SpecDb.CsHelpers.get_cast_insert(Player.spec_table())

      assert [:user_id]           
        == Sorcery.SpecDb.CsHelpers.get_require_update(Player.spec_table())

      assert [:user_id, :permissions, :opt, :name, :gene, :gender, :colors, :age] 
        == Sorcery.SpecDb.CsHelpers.get_require_insert(Player.spec_table())

      cs = Player.sorcery_update(%Player{id: player.id}, player)
      assert cs.valid?

      player = Map.put(player, :age, 9999999)
      assert player.age != 200
      cs = Player.sorcery_update(%Player{id: player.id}, player)
      assert cs.valid?
      assert cs.changes.age == 200

      assert cs.changes.gender in ["male", "female"]
      assert cs.changes.user_id == 24
    end
  end

  property "Optional fields" do
    check all player <- Player.gen(%{user_id: 24}) do
      assert valid?(player, Player.t())
      player = Map.delete(player, :opt)
      assert valid?(player, Player.t())
      player = Map.put(player, :opt, nil)
      assert valid?(player, Player.t())
      player = Map.put(player, :user_id, nil)
      assert !valid?(player, Player.t())
    end
  end



end
