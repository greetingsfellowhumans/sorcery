defmodule Sorcery.PortalServer.Query do
  @moduledoc """
  Quick recap:
  A child PS sends a PreMutation to the parent.
  The parent applies changes and creates a ChildrenMutation (replacing placeholders with ids, etc.)
  The parent also creates a diff, and runs the reverse query to check which child portals are affected.
  The reverse query is geared toward performance, but is a very low resolution solution with many false positives.
  The PortalServer.Query (*You are here*) is run by each child portal to get the knew matches for each lvar.
  This is slower and more precise, however the scope is extremely small. Instead of scanning an entire database, it is only the previous matches merged with the mutation changes.
  """
  import Sorcery.Helpers.Maps

  def run_query(portal, children_mutation) do
    db = build_db(portal, children_mutation)
    clauses = portal.query_module.clauses()
    finds = portal.query_module.finds()
    data = rebuild_data(clauses, portal.args, db)
           |> trim_by_find(finds)

    {:ok, data}
  end
   

  defp trim_by_find(data, finds) do
    Enum.reduce(data, %{}, fn {lvarkey, table}, acc ->
      lvar = "#{lvarkey}"
      case finds[lvarkey] do

        :* -> Map.put(acc, lvar, table)

        attrs when is_list(attrs) ->
          new_table = Enum.reduce(table, %{}, fn {id, entity}, acc ->
            new_entity = Map.take(entity, attrs)
            Map.put(acc, id, new_entity)
          end)
          Map.put(acc, lvar, new_table)

        err -> 
          dbg err
          acc

      end
    end)
  end


  # {{{ rebuild_data(clause, args, db)
  defp rebuild_data(clauses, args, db) do
    Enum.reduce(clauses, %{}, fn clause, acc ->
      acc = if Map.has_key?(acc, clause.lvar), do: acc, else: Map.put(acc, clause.lvar, db[clause.tk])
      current_data = acc[clause.lvar]
                     |> filter_table_by_clause(clause, args, acc)
      Map.put(acc, clause.lvar, current_data)
    end)
  end
  # }}}

  # {{{ filter_table_by_clause(table, clause, args, all_data)
  defp filter_table_by_clause(table, %{right_type: :lvar} = clause, args, all_data) do
    rights = all_data[clause.other_lvar] 
             |> Map.values()
             |> Enum.map(&(&1[clause.other_lvar_attr]))
             |> Enum.uniq()

    Enum.reduce(table, %{}, fn {id, entity}, acc ->
      left = Map.get(entity, clause.attr)
      matches? = Enum.any?(rights, fn right ->
        apply(Kernel, clause.op, [left, right])
      end)
      if matches?, do: Map.put(acc, id, entity), else: acc
    end)
  end
  defp filter_table_by_clause(table, %{right_type: :literal, right: right} = clause, args, all_data) do
    Enum.reduce(table, %{}, fn {id, entity}, acc ->
      left = Map.get(entity, clause.attr)
      matches? = apply(Kernel, clause.op, [left, right])
      if matches?, do: Map.put(acc, id, entity), else: acc
    end)
  end
  defp filter_table_by_clause(table, %{right_type: :arg} = clause, args, all_data) do
    right = args[clause.arg_name]
    Enum.reduce(table, %{}, fn {id, entity}, acc ->
      left = Map.get(entity, clause.attr)
      matches? = apply(Kernel, clause.op, [left, right])
      if matches?, do: Map.put(acc, id, entity), else: acc
    end)
  end
  defp filter_table_by_clause(table, _clause, _args, _all_data), do: table
  # }}}


  # {{{ build_db(portal, mutation)
  defp build_db(portal, m) do
    pdata = lvar_strings_to_atoms(portal)
    db = deep_merge(pdata, m.old_data)
    db = deep_merge(db, m.inserts)
    db = deep_merge(db, m.updates)
    Enum.reduce(m.deletes, db, fn {tk, ids}, acc ->
      table = Map.drop(db[tk], ids)
      Map.put(acc, tk, table)
    end)
  end
  defp lvar_strings_to_atoms(portal) do
    %{data: db, lvar_tks: lvar_tks} = portal.known_matches
    
    Enum.reduce(db, %{}, fn {lvar, table}, acc ->
      tk = lvar_tks[lvar]
      Map.put(acc, tk, table)
    end)
  end
  # }}}


end
