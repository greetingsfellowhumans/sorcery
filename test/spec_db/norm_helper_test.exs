defmodule Sorcery.SpecDb.NormHelperTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  use Norm


  test "types " do
    m = %{foo: %{t: :string}}
    assert valid?(%{foo: ""}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :string, min: 5}}
    assert !valid?(%{foo: ""}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :string, max: 5}}
    assert !valid?(%{foo: "123456789"}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :string, min: 0, max: 5}}
    assert valid?(%{foo: "123"}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :list, coll_of: :trinary}}
    assert  valid?(%{foo: []}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :list, coll_of: :trinary, length: 5}}
    assert  valid?(%{foo: [true, false, nil, nil, nil]}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :list, coll_of: :trinary, length: 5}}
    assert  !valid?(%{foo: [true, false, nil]}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :boolean }}
    assert  valid?(%{foo: false}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :integer }}
    assert  valid?(%{foo: -125}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :integer, min: 0 }}
    assert  !valid?(%{foo: -125}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :integer, max: 0 }}
    assert  valid?(%{foo: -125}, Sorcery.SpecDb.NormHelpers.build_schema(m))
  end



end
