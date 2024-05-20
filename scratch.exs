So I could have an ets :"sorcery_knownmatches_#{lvar}" table that basically stores the known right value(s) of every clause. Maybe index of clause
and I have another :portals table that holds {pid, portal_name, querymod, args}

So sorcery_knownmatches_lvar: {pid, portal_name, tk, entities}
So sorcery_portals_{portal_name}:  {child_pid, querymod, args}


def reverse_query(diff) do
  for {_pid, _portal_name, _querymod, _args} = results <- ets.all(:sorcery_rev_portals) do
    results = group_by(:pid, {portalname, querymod, args})
    Enum.filter(results, fn {pid, {portalname, querymod, args}} ->
      clauses = querymod.clauses(args)
                |> Enum.filter(&(&1.tk in diff.tks_affected))
                |> Enum.group_by(:lvar)
      Enum.any?(diff.rows, fn %{tk: tk, old: old, new: new} ->
        Enum.any?([old, new], fn entity ->
          Enum.any?(clauses, fn {lvar, clauses} ->
            
            # Also, if there are multiple clauses references the same other_lvar, those need to be grouped
            # So a match must be a match against all the clauses for a specific other entity
            # Maybe here we create a map of other entities...
            # %{"?teams" => %{1 => ...}}
            lclauses = group_by(:other_lvar)


            Enum.all?(lclauses, fn {other_lvar, clauses} ->
              ctx = %{args: args, pid, portalname, etc...}
              case other_lvar do
                "?" <> _ -> 
                  right_ents = :ets.select(:sorcery_known_matches_{other_lvar})
                  Enum.any?(right_ents, fn right_entity ->
                    ctx = Map.merge(ctx, :right_entity, right_entity)
                    Enum.all?(clauses, fn clause -> entity_matches_clause(entity, clause, ctx))
                  end)
                _nil -> Enum.all?(clauses, fn clause -> entity_matches_clause(entity, clause, ctx))
              end


            end)
          end)
        end)
      end)
    end)
    |> Enum.each(fn {pid, {portal_name, _, _}} -> 
      send(pid, {:rerun_queries, portal_name})
    end)

  end
end

  def entity_matches_clause(entity, clause, ctx) do
    ...
    apply(op, left, right)
  end

  # def other_lvar_clauses_match?({other_lvar, clauses}, ctx) 
  # def lvar_clauses_match?({lvar, clauses}, ctx) do
  # def entity_matches_clauses?(entity, clauses, ctx)
  # def diff_row_matches_clauses(row, clauses, ctx)
  # def group_clauses(c)

end
