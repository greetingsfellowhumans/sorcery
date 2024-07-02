defmodule Sorcery.StoreAdapter.Ecto.Query do
  @moduledoc false
  import Ecto.Query
  alias Sorcery.ReturnedEntities, as: RE
  alias Sorcery.StoreAdapter.Ecto.Thread

  def run_query(inner_state, wheres, finds) do
    repo = inner_state.args.repo_module

    config = inner_state.config_module.config()
    tk_map = config.schemas
    threads = Thread.all(wheres)
    ctx = %{repo: repo, config: config, tk_map: tk_map, finds: finds}

    # Possibly replace this with a Task.await_many
    results = Enum.map(threads, fn t -> run_thread(t, ctx) end)
              |> RE.merge()

    {:ok, results}
  end

  def run_thread(%Thread{order: order, where_groups: wgs} = thread, %{tk_map: tk_map} = ctx) do
    [lvar | tl_order] = order
    wheres = wgs[lvar]
    [%{tk: tk} | _] = wheres
    mod = tk_map[tk]
    finds = Map.filter(ctx.finds, fn {k, _} -> k in order end)
    q = from(x in mod, as: ^lvar)
    q = Enum.reduce(wheres, q, fn wc, q ->
      add_where(q, wc, tk_map)
    end)
    ctx = Map.put(ctx, :q, q)
    thread = Map.put(thread, :order, tl_order)
    ctx = continue_thread(thread, ctx)
          |> add_select(finds, thread)
    ctx.repo.all(ctx.q)
    |> convert_to_returned_entities()
    |> assign_tks(wgs)
  end

  def continue_thread(%{order: []}, ctx), do: ctx
  def continue_thread(%{order: [lvar | tl_order], where_groups: wgs} = thread, ctx) do
    wheres = wgs[lvar]
    ctx = add_join(ctx, lvar, wheres)
    thread = Map.put(thread, :order, tl_order)
    continue_thread(thread, ctx)
  end


  # {{{ add_join
  def add_join(%{tk_map: tk_map} = ctx, lvar, wheres) do
    [%{tk: tk} | _] = wheres
    mod = tk_map[tk]
    d_on = Enum.reduce(wheres, dynamic(true), fn 
      %{other_lvar: nil, op: :==, right: nil} = wc, d -> dynamic([{^lvar, child}], ^d and is_nil(field(child, ^wc.attr)) )
      %{other_lvar: nil, op: :!=, right: nil} = wc, d -> dynamic([{^lvar, child}], ^d and not is_nil(field(child, ^wc.attr)) )
      %{other_lvar: nil, op: :==} = wc, d -> dynamic([{^lvar, child}], ^d and field(child, ^wc.attr) == ^wc.right)
      %{other_lvar: nil, op: :!=} = wc, d -> dynamic([{^lvar, child}], ^d and field(child, ^wc.attr) != ^wc.right)
      %{other_lvar: nil, op: :in} = wc, d -> dynamic([{^lvar, child}], ^d and field(child, ^wc.attr) in ^wc.right)
      %{other_lvar: nil, op: :<}  = wc, d -> dynamic([{^lvar, child}], ^d and field(child, ^wc.attr) < ^wc.right)
      %{other_lvar: nil, op: :<=} = wc, d -> dynamic([{^lvar, child}], ^d and field(child, ^wc.attr) <= ^wc.right)
      %{other_lvar: nil, op: :>}  = wc, d -> dynamic([{^lvar, child}], ^d and field(child, ^wc.attr) > ^wc.right)
      %{other_lvar: nil, op: :>=} = wc, d -> dynamic([{^lvar, child}], ^d and field(child, ^wc.attr) >= ^wc.right)

      %{op: :==, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = wc, d -> 
        dynamic([{^parent_lvar, parent}, {^lvar, child}], ^d and field(child, ^wc.attr) == field(parent, ^parent_attr))
      %{op: :!=, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = wc, d -> 
        dynamic([{^parent_lvar, parent}, {^lvar, child}], ^d and field(child, ^wc.attr) != field(parent, ^parent_attr))
      %{op: :in, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = wc, d -> 
        dynamic([{^parent_lvar, parent}, {^lvar, child}], ^d and field(child, ^wc.attr) in field(parent, ^parent_attr))
      %{op: :<, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = wc, d -> 
        dynamic([{^parent_lvar, parent}, {^lvar, child}], ^d and field(child, ^wc.attr) < field(parent, ^parent_attr))
      %{op: :<=, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = wc, d -> 
        dynamic([{^parent_lvar, parent}, {^lvar, child}], ^d and field(child, ^wc.attr) <= field(parent, ^parent_attr))
      %{op: :>, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = wc, d -> 
        dynamic([{^parent_lvar, parent}, {^lvar, child}], ^d and field(child, ^wc.attr) > field(parent, ^parent_attr))
      %{op: :>=, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = wc, d -> 
        dynamic([{^parent_lvar, parent}, {^lvar, child}], ^d and field(child, ^wc.attr) >= field(parent, ^parent_attr))
    end)
    q = join(ctx.q, :left, [], child in ^mod, on: ^d_on, as: ^lvar)
    Map.put(ctx, :q, q)
  end
  # }}}


  def initial_from([wc | _], tk_map) do
    mod = tk_map[wc.tk]
    lvar = wc.lvar
    from(x in mod, as: ^lvar)
  end

  # {{{ WHERE
  def add_where(ecto_query, where_clause, tk_map) do
    case where_clause.right_type do
      :literal -> add_literal_clause(ecto_query, where_clause)
      :lvar -> add_lvar_clause(ecto_query, where_clause, tk_map)
    end
  end

  def add_literal_clause(q, where_clause) do
    %{lvar: lvar, attr: attr, right: value} = where_clause
    case {where_clause.op, value} do
      {:==, nil} -> where(q, [{^lvar, x}], is_nil(field(x, ^attr)))
      {:==, _} -> where(q, [{^lvar, x}], field(x, ^attr) == ^value)
      {:in, _} -> where(q, [{^lvar, x}], field(x, ^attr) in ^value)
      {:!=, nil} -> where(q, [{^lvar, x}], not is_nil(field(x, ^attr)))
      {:!=, _} -> where(q, [{^lvar, x}], field(x, ^attr))
      {:>, _} ->  where(q, [{^lvar, x}], field(x, ^attr) >  ^value)
      {:>=, _} -> where(q, [{^lvar, x}], field(x, ^attr) >= ^value)
      {:<, _} ->  where(q, [{^lvar, x}], field(x, ^attr) <  ^value)
      {:<=, _} -> where(q, [{^lvar, x}], field(x, ^attr) <= ^value)
    end
  end

  def add_lvar_clause(q, where_clause, tk_map) do
    %{tk: tk, lvar: child_lvar, attr: child_attr, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = where_clause
    mod = tk_map[tk]
    case where_clause.op do
      :== -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) == field(parent, ^parent_attr), as: ^child_lvar)
      :in -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) in field(parent, ^parent_attr), as: ^child_lvar)
      :!= -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) != field(parent, ^parent_attr), as: ^child_lvar)
      :> ->  join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) >  field(parent, ^parent_attr), as: ^child_lvar)
      :>= -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) >= field(parent, ^parent_attr), as: ^child_lvar)
      :< ->  join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) <  field(parent, ^parent_attr), as: ^child_lvar)
      :<= -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) <= field(parent, ^parent_attr), as: ^child_lvar)
    end
  end
  # }}}


  # {{{ SELECT/FIND
  def add_select(ctx, finds, _thread) do
    lvars = Map.keys(finds)
    [lvar | lvars] = lvars
    q = 
      ctx.q
      |> add_first_select(finds, lvar)
      |> add_next_select(finds, lvars)

    Map.put(ctx, :q, q)
  end

  def add_first_select(q, finds, lvar) do
    lvarstr = "#{lvar}"
    case Map.get(finds, lvar) do
      nil -> q
      _ -> select(q, [{^lvar, x}], %{^lvarstr => x})
    end
  end
  def add_next_select(q, _finds, []), do: q
  def add_next_select(q, finds, [lvar | lvars]) do
    lvarstr = "#{lvar}"
    case Map.get(finds, lvar) do
      nil -> add_next_select(q, finds, lvars)
      _ -> select_merge(q, [{^lvar, x}], %{^lvarstr => x})
    end
    |> add_next_select(finds, lvars)
    
  end
  # }}}

 
  # {{{ ReturnedEntities formatting
  def convert_to_returned_entities(li), do: convert_to_returned_entities(li, RE.new())
  def convert_to_returned_entities([], re), do: re
  def convert_to_returned_entities([items | li], re) do
    #convert_to_returned_entities(li, re)
    re = Enum.reduce(items, re, fn {lvarstr, entity}, re ->
      RE.put_entities(re, lvarstr, [entity])
    end)
    convert_to_returned_entities(li, re)
  end

  def assign_tks(re, wgs) do
    Enum.reduce(wgs, re, fn {lvar, [%{tk: tk} | _]}, acc ->
      lvar_str = "#{lvar}"
      RE.assign_lvar_tk(acc, lvar_str, tk)
    end)
  end
  # }}}

end
#defmodule Sorcery.StoreAdapter.Ecto.Query do
#  @moduledoc false
#  import Ecto.Query
#  alias Sorcery.ReturnedEntities, as: RE
#
#  _comment = ~s"""
#  Do not do this:
#
#  from p0, where p0...
#  join l1 on(...), where(l1)
#
#  Instead, do this
#  from p0, where p0...
#  join l1 on( ... and l1)
#
#  """
#
#
#  def run_query(inner_state, wheres, finds) do
#    repo = inner_state.args.repo_module
#
#    config = inner_state.config_module.config()
#    tk_map = config.schemas
#
#    q = initial_from(wheres, tk_map)
#    results = Enum.reduce(wheres, q, fn wc, q -> add_where(q, wc, tk_map) end)
#              |> add_select(finds)
#              |> repo.all()
#              |> convert_to_returned_entities()
#              |> assign_tks(wheres)
#    {:ok, results}
#  end
#
#  def initial_from([wc | _], tk_map) do
#    mod = tk_map[wc.tk]
#    lvar = wc.lvar
#    from(x in mod, as: ^lvar)
#  end
#
#  # {{{ WHERE
#  def add_where(ecto_query, where_clause, tk_map) do
#    case where_clause.right_type do
#      :literal -> add_literal_clause(ecto_query, where_clause)
#      :lvar -> add_lvar_clause(ecto_query, where_clause, tk_map)
#    end
#  end
#
#  def add_literal_clause(q, where_clause) do
#    %{lvar: lvar, attr: attr, right: value} = where_clause
#    case {where_clause.op, value} do
#      {:==, nil} -> where(q, [{^lvar, x}], is_nil(field(x, ^attr)))
#      {:==, _} -> where(q, [{^lvar, x}], field(x, ^attr) == ^value)
#      {:in, _} -> where(q, [{^lvar, x}], field(x, ^attr) in ^value)
#      {:!=, nil} -> where(q, [{^lvar, x}], not is_nil(field(x, ^attr)))
#      {:!=, _} -> where(q, [{^lvar, x}], field(x, ^attr))
#      {:>, _} ->  where(q, [{^lvar, x}], field(x, ^attr) >  ^value)
#      {:>=, _} -> where(q, [{^lvar, x}], field(x, ^attr) >= ^value)
#      {:<, _} ->  where(q, [{^lvar, x}], field(x, ^attr) <  ^value)
#      {:<=, _} -> where(q, [{^lvar, x}], field(x, ^attr) <= ^value)
#    end
#  end
#
#  def add_lvar_clause(q, where_clause, tk_map) do
#    %{tk: tk, lvar: child_lvar, attr: child_attr, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = where_clause
#    mod = tk_map[tk]
#    join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) == field(parent, ^parent_attr), as: ^child_lvar)
#    case where_clause.op do
#      :== -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) == field(parent, ^parent_attr), as: ^child_lvar)
#      :in -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) in field(parent, ^parent_attr), as: ^child_lvar)
#      :!= -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) != field(parent, ^parent_attr), as: ^child_lvar)
#      :> ->  join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) >  field(parent, ^parent_attr), as: ^child_lvar)
#      :>= -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) >= field(parent, ^parent_attr), as: ^child_lvar)
#      :< ->  join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) <  field(parent, ^parent_attr), as: ^child_lvar)
#      :<= -> join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) <= field(parent, ^parent_attr), as: ^child_lvar)
#    end
#  end
#  # }}}
#
#
#  # {{{ SELECT/FIND
#  def add_select(q, finds) do
#    lvars = Map.keys(finds)
#    [lvar | lvars] = lvars
#    q
#    |> add_first_select(finds, lvar)
#    |> add_next_select(finds, lvars)
#  end
#
#  def add_first_select(q, finds, lvar) do
#    lvarstr = "#{lvar}"
#    case Map.get(finds, lvar) do
#      nil -> q
#      :* -> select(q, [{^lvar, x}], %{^lvarstr => x})
#      find -> select(q, [{^lvar, x}], %{^lvarstr => map(x, ^find)})
#    end
#  end
#  def add_next_select(q, _finds, []), do: q
#  def add_next_select(q, finds, [lvar | lvars]) do
#    lvarstr = "#{lvar}"
#    case Map.get(finds, lvar) do
#      nil -> add_next_select(q, finds, lvars)
#      :* -> select_merge(q, [{^lvar, x}], %{^lvarstr => x})
#      find -> select_merge(q, [{^lvar, x}], %{^lvarstr => map(x, ^find)})
#    end
#    |> add_next_select(finds, lvars)
#    
#  end
#  # }}}
#
# 
#  # {{{ ReturnedEntities formatting
#  def convert_to_returned_entities(li), do: convert_to_returned_entities(li, RE.new())
#  def convert_to_returned_entities([], re), do: re
#  def convert_to_returned_entities([items | li], re) do
#    #convert_to_returned_entities(li, re)
#    re = Enum.reduce(items, re, fn {lvarstr, entity}, re ->
#      RE.put_entities(re, lvarstr, [entity])
#    end)
#    convert_to_returned_entities(li, re)
#  end
#
#  def assign_tks(re, clauses) do
#    Enum.reduce(clauses, re, fn %{lvar: lvar, tk: tk}, acc ->
#      lvar_str = "#{lvar}"
#      RE.assign_lvar_tk(acc, lvar_str, tk)
#    end)
#  end
#  # }}}
#
#end
