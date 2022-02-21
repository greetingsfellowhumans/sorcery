defmodule SubjectTest do
  use ExUnit.Case
  alias Sorcery.Src.Subject
  alias Sorcery.Src
  doctest Subject


  def query1(_src), do: {:ok, %{}}
  def query2(_src), do: {:ok, %{player: %{1 => %{id: 1, name: "Aaron", age: 100}}, dog: %{3 => %{id: 3, age: 7}}}}
  def query3(_src), do: {:ok, %{player: %{41 => %{id: 41, name: "You", age: 10}}}}
  def query4(_src), do: {:error, "Something bad happened"}


  def filter1(_, _db), do: %{}
  def filter2(_, db), do: Map.take(db, [:dog])
  def filter3(_, db), do: Map.take(db, [:player])
  def filter4(args, db) do
    uid = args.user_id
    p = get_in(db, [:player, uid])
    %{player: %{uid => p}}
  end


  @sub1 %Subject{query: &__MODULE__.query1/1, filter: &__MODULE__.filter1/2}
  @sub2 %Subject{query: &__MODULE__.query2/1, filter: &__MODULE__.filter2/2}
  @sub3 %Subject{query: &__MODULE__.query3/1, filter: &__MODULE__.filter3/2}
  @sub4 %Subject{query: &__MODULE__.query4/1, filter: &__MODULE__.filter4/2}

  @sub5 %Subject{query: &__MODULE__.query3/1, filter: &__MODULE__.filter4/2}
  @sub6 %Subject{query: &__MODULE__.query3/1, filter: &__MODULE__.filter2/2}

  # Get player 41 and all dogs
  @src1 %Src{subjects: [
    %Subject{query: &__MODULE__.query2/1, filter: &__MODULE__.filter1/2},
    %Subject{query: &__MODULE__.query3/1, filter: &__MODULE__.filter1/2},
    %Subject{query: &__MODULE__.query1/1, filter: &__MODULE__.filter2/2},
    %Subject{query: &__MODULE__.query1/1, filter: &__MODULE__.filter3/2},
  ], args: %{user_id: 41}}

  test "Fulfill correctly" do
    args = %{user_id: 41}
    msg1 = Subject.fulfill_all(%Src{subjects: [@sub1]})
    assert %{} == msg1.body

    msg2 = Subject.fulfill_all(%Src{subjects: [@sub2]})
    assert %{dog: %{3 => %{id: 3, age: 7}}} == msg2.body

    msg3 = Subject.fulfill_all(%Src{args: args, subjects: [@sub3]})
    assert %{player: %{41 => %{id: 41, name: "You", age: 10}}} == msg3.body

    msg4 = Subject.fulfill_all(%Src{subjects: [@sub4]})
    assert {:error, "Something bad happened"} == msg4.body

    assert :ok == msg1.status
    assert :ok == msg2.status
    assert :ok == msg3.status
    assert :error == msg4.status

    msg5 = Subject.fulfill_all(%Src{subjects: [@sub5], args: args})
    assert %{player: %{41 => %{id: 41, name: "You", age: 10}}} == msg5.body

    msg6 = Subject.fulfill_all(%Src{subjects: [@sub6]})
    assert %{} == msg6.body

    msg6 = Subject.fulfill_all(@src1)
    assert %{
      dog: %{3 => %{age: 7, id: 3}},
      player: %{41 => %{age: 10, id: 41, name: "You"}}
    } == msg6.body
  end



end
