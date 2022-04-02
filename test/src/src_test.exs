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


  test "Only updates what we need" do
    src = Src.new(%{person: %{1 => @p1, 2 => @p2}})
    
    assert src.changes_db == %{}
    src = Src.put_in(src, [:person, 2, :age], 1)
    
    assert %{
      1 => %{age: 100, id: 1, name: "Aaron"}, 
      2 => %{age: 1, id: 2, name: "Not Aaron"}
    } == get_in(src, [:person])
    
    expect_ch = %{person: %{2 => %{age: 1}}} 
    assert expect_ch == src.changes_db #Src.Access.diff(src) 
    assert 1 == get_in(src, [:person, 2, :age])
    assert %{age: 1, id: 2, name: "Not Aaron"} == get_in(src, [:person, 2])

    src = Src.delete(src, :person, 1)
    assert [person: 1] == src.deletes
    assert %{person: %{2 => %{age: 1}}}  == src.changes_db

    # Update entities that don't yet exist
    src = Src.put_in(src, [:foo, 8, :bar], "Baz")
    assert %{bar: "Baz"} == Src.get_in(src, [:foo, 8])
    
  end


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

  def int1(src) do
    update_in(src, [:person, 1, :age], fn age -> age + 1 end)
  end
  def int2(src) do
    update_in(src, [:person, 1, :age], fn age -> age * 2 end)
  end
  def int3(src) do
    age = get_in(src, [:person, 1, :age])
    if age > 200 do
      put_in(src, [:person, 1, :age], 200)
    else
      src
    end
  end

  def int4(src) do
    age = get_in(src, [:person, 1, :age])
    if age >= 200 do
      put_in(src, [:person, 1, :age], 200)
      |> Map.put(:interceptors, [])
    else
      src
    end
  end

  test "Interceptors" do
    src = Src.new(%{person: %{1 => @p1, 2 => @p2}})
          |> Map.put(:interceptors, [&int1/1, &int2/1])
          |> Sorcery.Src.Intercept.src_intercept()
    
    assert get_in(src, [:person, 1, :age]) == 202
    
    
    src = Src.new(%{person: %{1 => @p1, 2 => @p2}})
          |> Map.put(:interceptors, [&int1/1, &int2/1, &int3/1])
          |> Sorcery.Src.intercept()
    
    assert get_in(src, [:person, 1, :age]) == 200

    
    src = Src.new(%{person: %{1 => @p1, 2 => @p2}})
          |> Map.put(:interceptors, [&int1/1, &int3/1, &int2/1, &int3/1, &int1/1])
          |> Sorcery.Src.intercept()
    
    assert get_in(src, [:person, 1, :age]) == 201
    
    src = Src.new(%{person: %{1 => @p1, 2 => @p2}})
          |> Map.put(:interceptors, [
            &int1/1, # 100 + 1 = 101 
            &int1/1, # 101 + 1 = 102 
            &int4/1, # pass
            &int2/1, # 102 * 2 = 204
            &int4/1, # 204 > 200, so = 200, and stop interceptions
            &int1/1  # never gets reached.
          ])
          |> Sorcery.Src.intercept()
    
    assert get_in(src, [:person, 1, :age]) == 200
    assert 4 == Enum.count(src.complete_interceptors)
    assert 0 == Enum.count(src.interceptors)
    
    src = Src.new(%{person: %{1 => @p1, 2 => @p2}})
          |> Map.put(:interceptors, [&int1/1, &int1/1, &int1/1, &int1/1, &int1/1])
          |> Sorcery.Src.intercept()
    assert get_in(src, [:person, 1, :age]) == 105
    
    assert 0 == Enum.count(src.interceptors)
    assert 5 == Enum.count(src.complete_interceptors)
    
    # Recalculate src up to the point 3 interceptors ago
    src = Src.time_backward(src, 3)
    assert get_in(src, [:person, 1, :age]) == 102
    assert 3 == Enum.count(src.interceptors)
    assert 2 == Enum.count(src.complete_interceptors)
    
    # Pass over the next 2 interceptors without calculating anything
    src = Src.time_forward(src, 2)
    assert get_in(src, [:person, 1, :age]) == 102
    assert Src.get_in(src, [:person, 1, :age]) == 102
    assert 1 == Enum.count(src.interceptors)
    assert 4 == Enum.count(src.complete_interceptors)
  end


  @dog_src %Sorcery.Src{
    args: %{female_id: 1, male_id: 2},
    changes_db: %{},
    complete_interceptors: [],
    deletes: [],
    inserts: %{},
    interceptors: [],
    msg: %Sorcery.Msg{body: %{}, cb: &Sorcery.Msg.noop/0, flash: "", status: :ok},
    original_db: %{
      dog: %{
        1 => %{id: 1, name: "D1", sex: "female"},
        2 => %{id: 2, name: "D2", sex: "male"}
      }
    }
  }
  test "Inserting" do
    new_dog = %{father_id: 2, mother_id: 1, name: "D3", sex: "male"}
    expected = %{dog: %{"$sorcery:dog:1" => new_dog}}
    src = Src.put_in(@dog_src, [:dog, "$sorcery:dog:1"], new_dog)
    assert expected == src.changes_db
  end
  
end
