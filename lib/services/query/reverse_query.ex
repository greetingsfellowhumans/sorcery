defmodule Sorcery.Query.ReverseQuery do
  @moduledoc false

  alias Sorcery.ReturnedEntities, as: RE

  # {{{ Build the query
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

  def build_lvar_attr_set(_config_module, query_module, :reverse) do
    wheres = query_module.clauses()

    # FIRST PASS: lvar/attr pairs
    first_pass = Enum.reduce(wheres, [], fn %{lvar: lvar, attr: attr}, acc ->
      [{lvar, :id}, {lvar, attr} | acc]
    end)

    # SECOND PASS: when referring to another lvar
    second_pass = Enum.reduce(wheres, first_pass, fn 
      %{other_lvar: nil, other_lvar_attr: _attr}, acc -> acc
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
    Enum.group_by(set, fn {lvar, _attr} -> lvar end, fn {_, attr} -> attr end)
  end

  def get_known_matches(returned_entities, set) do
    finds = generate_find(set)
    Enum.reduce(finds, %{}, fn {lvar, li}, acc ->
      entities = RE.get_entities(returned_entities, "#{lvar}")
                |> Enum.map(&Map.take(&1, li))
                |> MapSet.new()
      Map.put(acc, lvar, entities)
    end)
  end

  def prune_results(returned_entities, set) do
    finds = generate_find(set)
    Enum.reduce(finds, RE.new(), fn {lvar, attrs}, re ->
      lvar_str = "#{lvar}"
      old = RE.get_entities(returned_entities, lvar_str)
      new = Enum.map(old, &Map.take(&1, attrs))
      RE.put_entities(re, lvar_str, new)
    end)
  end
  # }}}

  # {{{ Run the query
  def diff_matches_portal?(diff, portal) do
    lvar_tks = portal.query_module.raw_struct().lvar_tks
    clauses = portal.query_module.clauses(portal.args)
    Enum.any?(diff.rows, fn row ->
      lvars = get_possible_lvars(lvar_tks, row)
      diff_row_matches_portal?(row, portal, lvars, clauses)
    end)
  end

  def diff_row_matches_portal?(%{tk: _tk} = row, portal, lvars, clauses) do
    Enum.any?(lvars, fn lvar ->
      clauses = Enum.filter(clauses, &("#{&1.lvar}" == "#{lvar}"))
      Enum.all?(clauses, fn clause ->
        clause = Map.from_struct(clause)
        row_matches_clause?(row, clause, portal)
      end)
    end)
  end


  defp row_matches_clause?(row, %{op: op, attr: attr, right_type: :lvar, other_lvar: lvar, other_lvar_attr: lvar_attr} = clause, portal) do
    left_values = get_diff_row_values(row, attr)
    right_values = RE.get_entities( portal.known_matches, "#{lvar}") |> Enum.map(&(&1[lvar_attr]))
    Enum.any?(right_values, fn r ->
      Enum.any?(left_values, fn l ->
        apply(Kernel, op, [l, r])
      end)
    end)
  end
  defp row_matches_clause?(row, %{op: op, attr: attr, right_type: :literal, right: right}, _portal) do
    left_values = get_diff_row_values(row, attr)
    Enum.any?(left_values, fn l ->
      apply(Kernel, op, [l, right])
    end)
  end

  defp get_diff_row_values(row, attr) do
    li = []
    li = case row.old_entity do
      nil -> li
      %{^attr => v} -> [v | li]
    end
    case row.new_entity do
      nil -> li
      %{^attr => v} -> [v | li]
    end
  end


  defp get_possible_lvars(lvar_tks, %{tk: tk} = _row) do
    Enum.reduce(lvar_tks, [], fn {lvar, k}, acc -> 
      if k == tk do
        [String.to_existing_atom(lvar) | acc]
      else
        acc
      end
    end)
    |> Enum.uniq()
  end
  # }}}


end
