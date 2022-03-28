defmodule Sorcery.SpecDb.CsHelperTest do
  use ExUnit.Case
  use ExUnitProperties
  use Norm
  alias Sorcery.SpecDb.CsHelpers



  test "Changeset get cast update" do
    table = %{foo: %{t: :string}}
    assert [:foo] == CsHelpers.get_cast_update(table)

    table = %{foo: %{t: :string, cast_update: false}}
    assert [] == CsHelpers.get_cast_update(table)

    table = %{foo: %{t: :string, cast_update: true}}
    assert [:foo] == CsHelpers.get_cast_update(table)
  end


  test "Changeset get cast insert" do
    table = %{foo: %{t: :string}}
    assert [:foo] == CsHelpers.get_cast_insert(table)

    table = %{foo: %{t: :string, cast_insert: false}}
    assert [] == CsHelpers.get_cast_insert(table)

    table = %{foo: %{t: :string, cast_insert: true}}
    assert [:foo] == CsHelpers.get_cast_insert(table)
  end

  test "Changeset get require insert" do
    table = %{foo: %{t: :string}}
    assert [:foo] == CsHelpers.get_require_insert(table)

    table = %{foo: %{t: :string, require_insert: false}}
    assert [] == CsHelpers.get_require_insert(table)

    table = %{foo: %{t: :string, require_insert: true}}
    assert [:foo] == CsHelpers.get_require_insert(table)
  end

  # This is where things get weird. By default you want to update anything.
  test "Changeset get require update" do
    table = %{foo: %{t: :string}}
    assert [] == CsHelpers.get_require_update(table)

    table = %{foo: %{t: :string, require_update: false}}
    assert [] == CsHelpers.get_require_update(table)

    table = %{foo: %{t: :string, require_update: true}}
    assert [:foo] == CsHelpers.get_require_update(table)
  end



end
