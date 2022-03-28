defmodule Sorcery.SpecDb.SdHelperTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  use Norm
  alias Sorcery.SpecDb.SdHelpers


  property "Generates Players" do
    check all s <- SdHelpers.gen(%{foo: %{t: :string, min: 3, max: 45}}) do
      assert String.length(s.foo) <= 45
      assert String.length(s.foo) >= 3
    end
    check all s <- SdHelpers.gen(%{foo: %{t: :string, min: 5}}) do
      assert String.length(s.foo) >= 5
    end
    check all s <- SdHelpers.gen(%{foo: %{t: :string, max: 5}}) do
      assert String.length(s.foo) <= 5
    end


    check all s <- SdHelpers.gen(%{foo: %{t: :integer, min: 0, max: 5}}) do
      assert s.foo <= 5
      assert s.foo >= 0
    end

    check all s <- SdHelpers.gen(%{foo: %{t: :float, min: 0.0, max: 5.0}}) do
      assert s.foo <= 5.0
      assert s.foo >= 0.0
    end

    check all s <- SdHelpers.gen(%{foo: %{t: :boolean}}) do
      assert s.foo in [true, false]
    end

    check all s <- SdHelpers.gen(%{foo: %{t: :atom}}) do
      assert is_atom(s.foo)
    end

    check all s <- SdHelpers.gen(%{foo: %{t: :atom}}) do
      assert is_atom(s.foo)
    end

    check all s <- SdHelpers.gen(%{foo: %{t: :list, coll_of: :integer, length: 5}}) do
      assert Enum.count(s.foo) == 5
      assert Enum.all?(s.foo, &(is_integer(&1)))
    end

    check all s <- SdHelpers.gen(%{foo: %{t: :list, coll_of: :string, length: 5}}) do
      assert Enum.count(s.foo) == 5
      assert Enum.all?(s.foo, &(is_binary(&1)))
    end

  end


end
