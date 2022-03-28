defmodule Sorcery.Src.Utils do
  @moduledoc false

  use Norm
  alias Sorcery.Specs.Primative, as: T

  @contract remove_dels_from_db(T.db(), coll_of({T.tk(), T.id()})) :: T.db()
  def remove_dels_from_db(db, dels) do
    Enum.reduce(dels, db, fn {tk, id}, acc ->
      case Map.get(acc, tk) do
        nil -> acc
        table -> 
          table = Map.delete(table, id)
          Map.put(acc, tk, table)
      end
    end)
  end


  @contract all_ids(T.src(), T.tk()) :: coll_of(T.id())
  def all_ids(%{original_db: db1, changes_db: db2, deletes: dels}, tk) do
    db1 = remove_dels_from_db(db1, dels)
    db2 = remove_dels_from_db(db2, dels)
    table1 = Map.get(db1, tk, %{})
    table2 = Map.get(db2, tk, %{})
    ids1 = Map.keys(table1) |> MapSet.new()
    ids2 = Map.keys(table2) |> MapSet.new()
    MapSet.union(ids1, ids2)
    |> MapSet.to_list()
  end


  @contract entities_set(T.src()) :: coll_of({T.tk(), T.id()})
  def entities_set(%{original_db: og, changes_db: ch, deletes: del}) do
    delset = MapSet.new(del)
    oset = Enum.reduce(og, MapSet.new(), fn {tk, table}, acc ->
      ids = Map.keys(table)
      Enum.reduce(ids, acc, fn id, acc -> MapSet.put(acc, {tk, id}) end)
    end)
    Enum.reduce(ch, oset, fn {tk, table}, acc ->
      ids = Map.keys(table)
      Enum.reduce(ids, acc, fn id, acc -> MapSet.put(acc, {tk, id}) end)
    end)
    |> MapSet.difference(delset)
  end


end
