defmodule Sorcery.Query.ReverseQuery do
  @moduledoc false

  #import Sorcery.Helpers.Maps
  def build_lvar_attr_set(config_module, query_module, :forward) do
    strct = query_module.raw_struct()
    find = Map.get(strct, :find, %{})
    Enum.map(find, fn 
      {lvar_str, :*} ->
        lvar = String.to_atom(lvar_str)
        tk = Enum.find_value(query_module.clauses(), fn %{lvar: l, tk: tk} -> if l == lvar, do: tk, else: nil end)
        schema = config_module.config().schemas[tk]
        field_keys = Map.keys(schema.fields())
        field_keys = [:id | field_keys]
        Enum.map(field_keys, &({lvar, &1}))

      {lvar_str, li} when is_list(li) ->
        li = [:id | li]
        lvar = String.to_atom(lvar_str)
        Enum.map(li, &({lvar, &1}))
    end)
    |> List.flatten()
    |> MapSet.new()
  end

  def build_lvar_attr_set(config_module, query_module, :reverse) do
    wheres = query_module.clauses()

    # FIRST PASS: lvar/attr pairs
    first_pass = Enum.reduce(wheres, [], fn %{lvar: lvar, attr: attr}, acc ->
      [{lvar, :id}, {lvar, attr} | acc]
    end)

    # SECOND PASS: when referring to another lvar
    second_pass = Enum.reduce(wheres, first_pass, fn 
      %{other_lvar: nil, other_lvar_attr: attr}, acc -> acc
      %{other_lvar: lvar, other_lvar_attr: nil}, acc -> [{lvar, :id} | acc]
      %{other_lvar: lvar, other_lvar_attr: attr}, acc -> [{lvar, attr} | acc]
    end)

    MapSet.new(second_pass)
  end

  def generate_find([set1 | sets]) do
    Enum.reduce(sets, set1, &MapSet.union/2)
    |> generate_find()
  end
  def generate_find(set) do
    Enum.group_by(set, fn {lvar, _attr} -> "#{lvar}" end, fn {_, attr} -> attr end)
  end

end
