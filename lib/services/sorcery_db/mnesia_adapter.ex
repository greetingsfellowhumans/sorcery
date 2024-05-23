defmodule Sorcery.SorceryDb.MnesiaAdapter do
  import Sorcery.SorceryDb.SchemaAdapter



  # {{{ guard_in(op, left, li) 
  def guard_in(op, left, li) do
    op = sanitize_op(op)
    clauses = Enum.map(li, &({op, left, &1})) |> Enum.uniq()
    case op do
      :"=/=" -> List.to_tuple([:and | clauses])
      _ -> List.to_tuple([:or | clauses])
    end
  end
  # }}}


  def list_to_entity(values_li, attrs_atoms) do
    Enum.zip(attrs_atoms, values_li)
    |> Enum.into(%{})
  end

  # {{{ apply_changes
  def apply_changes(mutation, schemas) do
    apply_inserts(mutation, schemas)
    apply_updates(mutation, schemas)
    apply_deletes(mutation)
  end

  # Used in CreatePortal. 
  # In theory no change has happened so there is no need to notify anyone.
  def apply_fetched(data, schemas) do
    :mnesia.transaction(fn ->
      for {tk, table} <- data do
        attrs = get_attrs_list(schemas[tk])
        for {_id, entity} <- table do
          values = Enum.map(attrs, &(Map.get(entity, &1)))
          tup = List.to_tuple([tk | values])
          :mnesia.write(tup)
        end
      end
    end)
  end


  defp apply_inserts(%{inserts: inserts}, schemas) do
    for {tk, table} <- inserts do
      attrs = get_attrs_list(schemas[tk])
      for {_id, entity} <- table do
        values = Enum.map(attrs, &(Map.get(entity, &1)))
        tup = List.to_tuple([tk | values])
        :mnesia.write(tup)
      end
    end
  end
  defp apply_inserts(_, _), do: nil

  defp apply_updates(%{updates: updates}, schemas) do
    for {tk, table} <- updates do
      attrs = get_attrs_list(schemas[tk])
      for {_id, entity} <- table do
        values = Enum.map(attrs, &(Map.get(entity, &1)))
        tup = List.to_tuple([tk | values])
        dbg tup
        :mnesia.write(tup)
        |> dbg()
      end
    end
  end
  defp apply_updates(_, _), do: nil

  defp apply_deletes(%{deletes: deletes}) do
    for {tk, ids} <- deletes do
      for id <- ids do
        :mnesia.delete({tk, id})
      end
    end
  end
  defp apply_deletes(_), do: nil
  # }}}


  # {{{ sanitize_op/1 
  def sanitize_op(:==), do: :"=:="
  def sanitize_op(:in), do: :"=:=" # This should only be used inside guard_in map function
  def sanitize_op(:!=), do: :"=/="
  def sanitize_op(:<=), do: :"=<"
  def sanitize_op(op), do: op
  # }}}

end
