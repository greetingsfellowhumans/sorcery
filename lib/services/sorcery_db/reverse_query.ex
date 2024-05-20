defmodule Sorcery.SorceryDb.ReverseQuery do
  @moduledoc false
  use Norm
  import Sorcery.Specs
  import Sorcery.Helpers.Ets

  # Return the set of {pid, portal_name} pairs that are affected by this diff.
  def reverse_query(diff) do
    portal_names = get_portal_names_affected_by_diff(diff)
    reverse_query(diff, portal_names, [])
  end
  def reverse_query(diff, [portal_name | portal_names], passing_pid_portals) do
    passing_pids = Enum.map(passing_pid_portals, &(Enum.at(&1, 0)))
    instances = get_all_portal_instances(portal_name, exclude_pids: passing_pids)
    ctx = %{diff: diff, portal_name: portal_name}

    new_passing_pid_portals = intersect_clauses_and_diffs(instances, ctx)
    reverse_query(diff, portal_names, new_passing_pid_portals ++ passing_pid_portals)
  end
  def reverse_query(_, [], passing_pid_portals), do: passing_pid_portals

  def intersect_clauses_and_diffs(portal_instances, %{diff: diff, portal_name: portal_name} = ctx) do
    Enum.reduce(portal_instances, [], fn [pid, query_mod, args], acc ->
      ctx = Map.merge(ctx, %{pid: pid, query_mod: query_mod, args: args})

      clauses = query_mod.clauses(args)
              |> Enum.filter(&(&1.tk in diff.tks_affected))
              |> Enum.group_by(&(&1.lvar))

      intersects? = Enum.any?(diff.rows, fn %{tk: tk, old_entity: old_ent, new_entity: new_ent} ->
        Enum.any?([old_ent, new_ent], fn entity ->
          Enum.any?(clauses, fn {lvar, clauses} ->
            lclauses = Enum.group_by(clauses, &(&1.other_lvar))
            entity_matches_lclauses(entity, lclauses, ctx)
          end)
        end)
      end)

      if intersects?, do: [{pid, portal_name} | acc], else: acc

    end)
  end

  # {{{ get_portal_names_affected_by_diff(diff) 
  def put_all_portal_names(portal_name) do
    ensure_table(:sorcery_portal_names, [:set, :public, :named_table, read_concurrency: true, write_concurrency: true])
    :ets.insert(:sorcery_portal_names, {portal_name})
  end
  def get_all_portal_names() do
    ensure_table(:sorcery_portal_names, [:set, :public, :named_table, read_concurrency: true, write_concurrency: true])
    :ets.match(:sorcery_portal_names, {:"$1"})
    |> List.flatten()
  end
  def get_portal_names_affected_by_diff(%{tks_affected: tks} = _diff) do
    difftks = MapSet.new(tks)
    names = get_all_portal_names()
    |> Enum.filter(fn name ->
      table_name = get_portal_table_name(name)
      case :ets.select(table_name, [{ {:_, :"$2", :_}, [], [:"$2"]}], 1) do
        {[query_mod], _} -> 
          qmtks = query_mod.tks_affected() |> MapSet.new()
          !MapSet.disjoint?(difftks, qmtks)
        _ -> false
      end
    end)
  end
  # }}}

  # {{{ portal_tables (i.e.  {:"sorcery_portals?portal=:get_battle", child_pid, query_mod, args})
  def get_portal_table_name(portal_name) do
    "sorcery_portals?portal=:#{portal_name}"
    |> String.to_atom()
  end

  def put_portal_table(portal_name, child_pid, query_mod, args) do
    table = get_portal_table_name(portal_name)
    ensure_table(table, [:set, :public, :named_table, read_concurrency: true, write_concurrency: true])
    put_all_portal_names(portal_name)

    :ets.insert(table, {child_pid, query_mod, args})
  end

  def get_all_portal_instances(portal_name, opts \\ []) do
    table_name = get_portal_table_name(portal_name)
    guards = []
    guards = case Keyword.get(opts, :exclude_pids) do
      pids when is_list(pids) -> 
        li = Enum.map(pids, fn pid ->
          {:"=/=", :"$1", pid}
        end)
        li ++ guards
      _ -> guards
    end
    results = :ets.select(table_name, [{ {:"$1", :"$2", :"$3"}, guards, [:"$$"] }])
  end

  # }}}

  # {{{ watcher_tables (i.e. {:"sorcery_watchers?portal=:get_battle&lvar=?team", entities_list})

  def get_watcher_table_name(portal_name, lvar) do
    "sorcery_watchers?portal=#{portal_name}&lvar=#{lvar}"
    |> String.to_atom()
  end

  def repopulate_watcher_table(portal_name, lvar, pid, entities) when is_list(entities) do
    table_name = get_watcher_table_name(portal_name, lvar)

    # Create the table if it doesn't already exist
    case :ets.info(table_name) do
      :undefined -> :ets.new(table_name, [:set, :public, :named_table, read_concurrency: true, write_concurrency: true])
      _ -> :noop
    end
   
    # delete all the entries for this pid
    :ets.insert(table_name, {pid, entities})
  end

  def get_watcher_entities(portal_name, lvar, pid) do
    table_name = get_watcher_table_name(portal_name, lvar)
    case :ets.info(table_name) do
      :undefined -> []
      _ -> 
        case :ets.lookup(table_name, pid) do
          [{_pid, entities} | _] -> entities
          _ -> []
        end
    end
  end

  # }}}


  # {{{ entity_matches_lclauses(entity, lclauses, ctx)
  defp lclauses?(), do: map_of(one_of([nil?(), lvark?()]), coll_of(clause?()))

  @contract entity_matches_lclauses(entity?(), lclauses?(), schema(%{pid: pid?(), args: map?(), portal_name: atom?()})) :: bool?()
  def entity_matches_lclauses(entity, lclauses, ctx) do
    
    Enum.all?(lclauses, fn {other_lvark, where_clauses} ->
      case "#{other_lvark}" do
        "?" <> _ -> 
          right_ents = get_watcher_entities(ctx.portal_name, other_lvark, ctx.pid)
          Enum.any?(right_ents, fn right_entity ->
            ctx = Map.put(ctx, :right_entity, right_entity)
            Enum.all?(where_clauses, fn clause -> entity_matches_clause(entity, clause, ctx) end)
          end)
        bap ->  
          Enum.all?(where_clauses, fn clause -> entity_matches_clause(entity, clause, ctx) end)
      end
    end)


  end
  # }}}


  # {{{ entity_matches_clause(entity, clause, ctx)
  defp literal_ctx?(), do: selection(schema(%{}), [])
  defp args_ctx?(), do: selection(schema(%{args: map?()}), [])
  defp lvar_ctx?(), do: selection(schema(%{right_entity: entity?()}), [])
  defp ctx?(), do: one_of([literal_ctx?(), args_ctx?(), lvar_ctx?()])
  defp get_op(%{op: op}) when op in [:==, :in, :!=, :>, :>=, :<, :<=], do: op
  defp get_op(clause), do: raise ":#{clause[:op]} is not a valid SrcQl op atom."
  defp apply_olr(:in, left, right), do: left in right
  defp apply_olr(op, left, right), do: apply(Kernel, op, [left, right])

  @contract entity_matches_clause(entity?(), clause?(), ctx?()) :: bool?()
  def entity_matches_clause(entity, %{right_type: :literal} = clause, _ctx) do
    op = get_op(clause)
    left = entity[clause.attr]
    right = clause.right
    apply_olr(op, left, right)
  end
  def entity_matches_clause(entity, %{right_type: :arg, arg_name: arg_name} = clause, %{args: args}) do
    op = get_op(clause)
    left = entity[clause.attr]
    right = args[arg_name]
    apply_olr(op, left, right)
  end
  def entity_matches_clause(entity, %{right_type: :lvar} = clause, %{right_entity: rent}) do
    op = get_op(clause)
    left = entity[clause.attr]
    right = rent[clause.other_lvar_attr]
    apply_olr(op, left, right)
  end
  # }}}


end
