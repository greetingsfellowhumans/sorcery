defmodule Sorcery.StoreAdapter.Ecto.Query do
  @moduledoc false
  import Ecto.Query
  alias Sorcery.ReturnedEntities, as: RE


  def run_query(portal_server_state, wheres, finds) do
    repo = portal_server_state.args.repo_module
    config = portal_server_state.config_module.config()
    tk_map = config.schemas

    q = initial_from(wheres, tk_map)
    Enum.reduce(wheres, q, fn wc, q -> add_where(q, wc, tk_map) end)
    |> add_select(finds)
    |> repo.all()
    |> convert_to_returned_entities()
    |> assign_tks(wheres)
  end

  def initial_from([wc | _], tk_map) do
    mod = tk_map[wc.tk]
    lvar = wc.lvar
    #dbg mod
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
    case where_clause.op do
      :== -> where(q, [{^lvar, x}], field(x, ^attr) == ^value)
      :in -> where(q, [{^lvar, x}], field(x, ^attr) in ^value)
      :!= -> where(q, [{^lvar, x}], field(x, ^attr) != ^value)
      :> ->  where(q, [{^lvar, x}], field(x, ^attr) >  ^value)
      :>= -> where(q, [{^lvar, x}], field(x, ^attr) >= ^value)
      :< ->  where(q, [{^lvar, x}], field(x, ^attr) <  ^value)
      :<= -> where(q, [{^lvar, x}], field(x, ^attr) <= ^value)
    end
  end

  def add_lvar_clause(q, where_clause, tk_map) do
    %{tk: tk, lvar: child_lvar, attr: child_attr, other_lvar: parent_lvar, other_lvar_attr: parent_attr} = where_clause
    mod = tk_map[tk]
    join(q, :left, [{^parent_lvar, parent}], child in ^mod, on: field(child, ^child_attr) == field(parent, ^parent_attr), as: ^child_lvar)
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
  def add_select(q, finds) do
    lvars = Map.keys(finds)
    [lvar | lvars] = lvars
    q
    |> add_first_select(finds, lvar)
    |> add_next_select(finds, lvars)
  end

  def add_first_select(q, finds, lvar) do
    lvarstr = "#{lvar}"
    case Map.get(finds, lvar) do
      nil -> q
      :* -> select(q, [{^lvar, x}], %{^lvarstr => x})
      find -> select(q, [{^lvar, x}], %{^lvarstr => map(x, ^find)})
    end
  end
  def add_next_select(q, _finds, []), do: q
  def add_next_select(q, finds, [lvar | lvars]) do
    lvarstr = "#{lvar}"
    case Map.get(finds, lvar) do
      nil -> add_next_select(q, finds, lvars)
      :* -> select_merge(q, [{^lvar, x}], %{^lvarstr => x})
      find -> select_merge(q, [{^lvar, x}], %{^lvarstr => map(x, ^find)})
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

  def assign_tks(re, clauses) do
    Enum.reduce(clauses, re, fn %{lvar: lvar, tk: tk}, acc ->
      lvar_str = "#{lvar}"
      RE.assign_lvar_tk(acc, lvar_str, tk)
    end)
  end
  # }}}

end
