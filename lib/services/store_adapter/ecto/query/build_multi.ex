defmodule Sorcery.StoreAdapter.Ecto.Query.BuildMulti do
  @moduledoc false
  import Ecto.Query
  alias Ecto.Multi, as: M

  # {{{ WIP build_multi
  @doc ~s"""
  Fill out ctx.multi, returning ctx.
  The result can be used like App.Repo.transaction(ctx.multi)
  """
  def build_multi(ctx) do
    wheres = Enum.group_by(ctx.wheres, &(&1.lvar))
    order = Enum.map(ctx.wheres, &(&1.lvar)) |> Enum.uniq()

    multi = Enum.reduce(order, M.new(), &handle_entire_lvar(&1, &2, wheres[&1], ctx))

    Map.put(ctx, :multi, multi)
  end
  # }}}

  # {{{ WIP handle_entire_lvar
  _doc = ~s"""
  Given an Lvar and a multi, adds the query to the multi
  """
  defp handle_entire_lvar(lvar, multi, [hd_clause | _] = clauses, ctx) do
    mod = ctx.tk_map[hd_clause.tk]
    M.all(multi, lvar, fn results -> 
      Enum.reduce(clauses, from(x in mod, as: ^lvar), &handle_single_clause(&1, &2, results))
    end)
  end
  # }}}


  # {{{ WIP handle_single_clause
  _doc = ~s"""
  Adds a single where clause to a query
  """
  defp handle_single_clause(clause, q, results) do
    clause = rewrite_fk_clause(clause, results)
    %{lvar: lvar, attr: attr, right: value, op: op} = clause
    case {op, value} do
      {:==, nil} -> where(q, [{^lvar, x}], is_nil(field(x, ^attr)))
      {:==, _} ->   where(q, [{^lvar, x}], field(x, ^attr) == ^value)
      {:in, _} ->   where(q, [{^lvar, x}], field(x, ^attr) in ^value)
      {:!=, nil} -> where(q, [{^lvar, x}], not is_nil(field(x, ^attr)))
      {:!=, _} ->   where(q, [{^lvar, x}], field(x, ^attr))
      {:>, _} ->    where(q, [{^lvar, x}], field(x, ^attr) >  ^value)
      {:>=, _} ->   where(q, [{^lvar, x}], field(x, ^attr) >= ^value)
      {:<, _} ->    where(q, [{^lvar, x}], field(x, ^attr) <  ^value)
      {:<=, _} ->   where(q, [{^lvar, x}], field(x, ^attr) <= ^value)
    end
  end

  defp rewrite_fk_clause(%{right_type: :lvar, other_lvar: olvar, other_lvar_attr: oattr} = clause, results) do
    other = results[olvar]
    right = Enum.map(other, &Map.get(&1, oattr))

    clause
    |> Map.put(:op, :in)
    |> Map.put(:right, right)
  end
  defp rewrite_fk_clause(clause, _), do: clause
  # }}}


  # {{{ dummy_results DELETE ME
  def dummy_results() do
    M.new()
    |> M.all(:"?player", fn _ ->
      from(p in Src.Schemas.Player)
      |> where([p], p.id == 2)
    end)
    |> M.all(:"?spell_type", fn _ ->
      from(s in Src.Schemas.SpellType)
      |> where([s], s.power > 0)
    end)
    |> M.all(:"?spells", fn m ->
      player_ids = Enum.map(m[:"?player"], &(&1.id))
      type_ids = Enum.map(m[:"?spell_type"], &(&1.id))
      from(s in Src.Schemas.SpellInstance)
      |> where([s], s.player_id in ^player_ids)
      |> where([s], s.type_id in ^type_ids)
    end)
    #|> Sorcery.Repo.transaction()
  end
  # }}}

end
