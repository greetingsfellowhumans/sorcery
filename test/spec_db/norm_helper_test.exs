defmodule Sorcery.SpecDb.NormHelperTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  use Norm
  #alias Sorcery.SpecDb.SdHelpers


  test "types " do
    m = %{foo: %{t: :string}}
    assert  valid?(%{foo: ""}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :list, coll_of: :trinary}}
    assert  valid?(%{foo: []}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    m = %{foo: %{t: :list, coll_of: :trinary, length: 5}}
    assert  valid?(%{foo: [true, false, nil, nil, nil]}, Sorcery.SpecDb.NormHelpers.build_schema(m))

    # @TODO Norm doesn't check list size
    m = %{foo: %{t: :list, coll_of: :trinary, length: 5}}
    assert  !valid?(%{foo: [true, false, nil]}, Sorcery.SpecDb.NormHelpers.build_schema(m))
  end


end
