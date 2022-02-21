defmodule PersonTest do
  defstruct [:id, :name, :age]
end


defmodule SrcTest do
  use ExUnit.Case
  alias Sorcery.Src
  alias Sorcery.Src.Utils
  doctest Src
  doctest Src.Utils

  @p1 %{
    id: 1,
    name: "Aaron",
    age: 100 # Gee I'm old...
  }

  @p2 %{
    id: 2,
    name: "Not Aaron",
    age: 123
  }


  test "All IDS" do
    src = Src.new(%{person: %{1 => @p1, 2 => @p2}})
    assert Utils.all_ids(src, :person) == [1, 2]
  end


  test "Access" do
    src = Src.new(%{:person => %{1 => @p1, 2 => @p2}})
    assert src.original_db[:person][1].name == "Aaron"
    src = put_in(src, [:person, 1, :name], "NOT Aaron")
    assert get_in(src, [:person, 1, :name]) == "NOT Aaron"
    assert src.original_db[:person][1].name == "Aaron"
    assert src.changes_db[:person][1].name == "NOT Aaron"
    assert get_in(src, [:person, 1]) == %{id: 1, name: "NOT Aaron", age: 100}

    src = %Src{original_db: %{:person => %{1 => @p1, 2 => @p2}}, deletes: [{:person, 1}]}
    assert nil == get_in(src, [:person, 1])
  end

  test "Enumerable" do
    src = Src.new(%{person: %{1 => @p1, 2 => @p2}, foo: %{1 => @p1}})
    assert Enum.count(src) == 3

    assert Enum.member?(src, {:person, 2}) == true
    assert Enum.member?(src, {:person, 22}) == false

    id_sum = Enum.reduce(src, 0, fn {_tk, id, _item}, acc -> id + acc end)
    assert id_sum == 4


    src = %Src{original_db: %{person: %{1 => @p1, 2 => @p2}, foo: %{1 => @p1}}, deletes: [{:person, 1}]}
    id_sum = Enum.reduce(src, 0, fn {_tk, id, _item}, acc -> id + acc end)
    assert id_sum == 3
  end


end
