defmodule Sorcery.Query.TkQuery do
  @moduledoc false

  def from_tk_map(mod, args, tk_data) do
    clauses = mod.clauses(args)
    finds = mod.finds()

    Enum.reduce(clauses, %{}, fn clause, acc ->
      apply_clause(clause, args, acc, tk_data)
    end)
    |> apply_finds(finds)
    |> prettify()
  end

  defp apply_finds(datak, finds) do
    Enum.reduce(finds, %{}, fn 
      {lvark, :*}, acc -> Map.put(acc, lvark, datak[lvark])
      {lvark, li}, acc -> 
        entities = Enum.map(datak[lvark], &(Map.take(&1, li)))
        Map.put(acc, lvark, entities)
    end)
  end

  defp prettify(data) do
    Enum.reduce(data, %{}, fn {lvark, li}, acc ->
      lvar = "#{lvark}"
      table = Enum.reduce(li, %{}, fn 
        %{id: _} = entity, table -> Map.put(table, entity.id, entity) 
        _, table -> table
      end)
      Map.put(acc, lvar, table)
    end)
  end

  defp apply_clause(%{lvar: lvark, attr: attr, right_type: :literal, op: op, right: right} = clause, _args, curr_data, all_data) do
    set = get_set(clause, curr_data, all_data)

    new_set = Enum.filter(set, fn entity ->
      left = Map.get(entity, attr)
      apply(Kernel, op, [left, right])
    end)

    Map.put(curr_data, lvark, new_set)
  end
  defp apply_clause(%{lvar: lvark, attr: attr, right_type: :arg, arg_name: arg_name, op: op} = clause, args, curr_data, all_data) do
    set = get_set(clause, curr_data, all_data)

    new_set = Enum.filter(set, fn entity ->
      left = Map.get(entity, attr)
      right = args[arg_name]
      apply(Kernel, op, [left, right])
    end)

    Map.put(curr_data, lvark, new_set)
  end
  defp apply_clause(%{lvar: lvark, attr: attr, right_type: :lvar, op: op, other_lvar: other_lvark, other_lvar_attr: other_attr} = clause, _args, curr_data, all_data) do
    other_set = Map.get(curr_data, other_lvark) || []
    set = get_set(clause, curr_data, all_data)

    new_set = Enum.filter(set, fn entity ->
      left = Map.get(entity, attr)
      Enum.any?(other_set, fn other_entity ->
        right = Map.get(other_entity, other_attr)
        apply(Kernel, op, [left, right])
      end)
    end)

    Map.put(curr_data, lvark, new_set)
  end

  defp get_set(%{lvar: lvark, tk: tk}, curr_data, all_data) do
    Map.get(curr_data, lvark) || Map.values(Map.get(all_data, tk))
  end
  
end
