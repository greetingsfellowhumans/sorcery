defmodule Sorcery.Schema.Generation.EntryTest do
  use ExUnit.Case
  alias Sorcery.Schema, as: S
  alias Src.Schemas.Player, as: Player
  #alias Src.Schemas.SpellType, as: ST
  alias Src.Schemas.Types

  doctest S

  # {{{ Bool
  test "Generate booleans" do
    for t <- Types.gen(10) do
      # Mandatory Bools
      f = Map.get(t, :bool_mandatory)
      assert f in [true, false]

      # Optional Int
      f = Map.get(t, :bool_optional)
      assert f in [true, false, nil]
    end
    for t <- Types.gen(%{bool_mandatory: true, bool_optional: nil}, 10) do
      f = Map.get(t, :bool_mandatory)
      assert true == f

      f = Map.get(t, :bool_optional)
      assert is_nil(f)
    end
  end
  # }}}

  # {{{ INTS
  test "Generate ints" do
    for t <- Types.gen(10) do
      # Mandatory Int
      f = Map.get(t, :int_mandatory)
      assert is_integer(f)
      assert 0 <= f
      assert 10 >= f

      # Optional Int
      f = Map.get(t, :int_optional)
      assert is_integer(f) || is_nil(f)
      if is_integer(f) do
        assert -10 <= f
        assert 10 >= f
      else
        assert is_nil(f)
      end
    end
    for t <- Types.gen(%{int_mandatory: 5, int_optional: 5}, 10) do
      f = Map.get(t, :int_mandatory)
      assert 5 == f

      f = Map.get(t, :int_optional)
      assert 5 == f
    end
  end
  # }}}
  
  # {{{ Floats
  test "Generate floats" do
    for %{float_mandatory: m, float_optional: o} <- Types.gen(10) do
      # Mandatory
      assert is_float(m)
      assert 0 <= m
      assert 10 >= m

      # Optional
      if is_float(o) do
        assert -10 <= o
        assert 10 >= o
      else
        assert is_nil(o)
      end
    end
    for %{float_mandatory: m, float_optional: o} <- Types.gen(%{float_mandatory: 5.0, float_optional: 5.0}, 10) do
      assert 5 == m
      assert 5 == o
    end
  end
  # }}}

  # {{{ Strings
  test "Generate strings" do
    for %{string_mandatory: m, string_optional: o} <- Types.gen(10) do
      # Mandatory
      assert is_binary(m)
      assert 10 <= String.length(m)
      assert 20 >= String.length(m)

      # Optional
      if is_binary(o) do
        assert 10 <= String.length(o)
        assert 20 >= String.length(o)
      else
        assert is_nil(o)
      end
    end
    for %{string_mandatory: m, string_optional: o} <- Types.gen(%{string_mandatory: "hello", string_optional: "good bye"}, 10) do
      assert "hello" == m
      assert "good bye" == o
    end
  end
  # }}}

  # {{{ List
  test "Generate lists" do
    for %{list_mandatory: m, list_optional: o, list_inner: i} <- Types.gen(10) do
      # Mandatory
      assert is_list(m)
      assert 10 <= Enum.count(m)
      assert 20 >= Enum.count(m)

      ## Optional
      if is_list(o) do
        assert 10 <= Enum.count(o)
        assert 20 >= Enum.count(o)
      else
        assert is_nil(o)
      end

      ## Inner
      assert 5 <= Enum.count(i)
      assert 10 >= Enum.count(i)
      for inner <- i do
        assert 15 <= String.length(inner)
        assert 25 >= String.length(inner)
      end

    end
  end
  # }}}

  # {{{ Map
  test "Generate maps" do
    ents = Types.gen(10)
    map_mandatories = Enum.map(ents, &(&1.map_mandatory))
    assert Enum.all?(map_mandatories, &is_map/1)
    map_optionals = Enum.map(ents, &(&1.map_optional))
    assert Enum.any?(map_optionals, &is_map/1)
    assert Enum.any?(map_optionals, &is_nil/1)
  end
  # }}}

  # {{{ Schema generation
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

    assert is_list(demo_player.a_list)
  end
  # }}}


end
