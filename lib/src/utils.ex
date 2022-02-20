defmodule Sorcery.Src.Utils do
  use Norm
  alias Sorcery.Specs.Primative, as: T


  @contract all_ids(T.src(), T.tk()) :: coll_of(T.id())
  def all_ids(%{original_db: db1, changes_db: db2}, tk) do
    table1 = Map.get(db1, tk, %{})
    table2 = Map.get(db2, tk, %{})
    ids1 = Map.keys(table1) |> MapSet.new()
    ids2 = Map.keys(table2) |> MapSet.new()
    MapSet.union(ids1, ids2)
    |> MapSet.to_list()
  end


  @contract entities_set(T.src()) :: coll_of({T.tk(), T.id()})
  def entities_set(%{original_db: og, changes_db: ch}) do
    oset = Enum.reduce(og, MapSet.new(), fn {tk, table}, acc ->
      ids = Map.keys(table)
      Enum.reduce(ids, acc, fn id, acc -> MapSet.put(acc, {tk, id}) end)
    end)
    Enum.reduce(ch, oset, fn {tk, table}, acc ->
      ids = Map.keys(table)
      Enum.reduce(ids, acc, fn id, acc -> MapSet.put(acc, {tk, id}) end)
    end)
  end


end
