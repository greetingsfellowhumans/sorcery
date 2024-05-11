#defmodule Sorcery.StoreAdapter.InMemory.Query do
#  alias Sorcery.ReturnedEntities, as: RE
#
#  def run_query(state, clauses, finds) do
#    db = state.args.db
#    results = Enum.reduce(clauses, %{}, fn clause, acc ->
#      entities = if Map.has_key?(acc, clause.lvar), do: acc[clause.lvar], else: db[clause.tk] |> Map.values()
#      entities = filter_entities_by_clause(entities, clause, acc)
#      Map.put(acc, clause.lvar, entities)
#    end)
#    re = RE.new()
#    re = Enum.reduce(results, re, fn {lvar, entities}, re ->
#      RE.put_entities(re, lvar, entities)
#    end)
#
#    {:ok, re}
#  end
#
#
#  defp filter_entities_by_clause(entities, %{attr: attr, right: right, op: op, other_lvar: nil} = clause, acc) do
#    Enum.filter(entities, fn entity ->
#      left = entity[attr]
#      apply(Kernel, op, [left, right])
#    end)
#  end
#  defp filter_entities_by_clause(entities, %{attr: attr, other_lvar: lvar} = clause, acc) do
#    other_attr = Map.get(clause, :other_lvar_attr, :id)
#    right = Enum.map(acc[lvar], &(&1[other_attr]))
#
#    Enum.filter(entities, fn entity ->
#      left = entity[attr]
#      left in right
#    end)
#  end
#
#end
