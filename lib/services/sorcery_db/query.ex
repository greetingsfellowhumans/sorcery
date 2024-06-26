defmodule Sorcery.SorceryDb.Query do
  @moduledoc false
  import Sorcery.SorceryDb.{MnesiaAdapter, SchemaAdapter}

  # Builds a match_spec guard clause out of a SrcQL WhereClause
  # {{{ where_to_guard(clause, data, args, schema_attrs)
  def where_to_guard(%{op: op, attr: attr, tk: tk, right: right, right_type: :literal} = _clause, _data, _args, schemas_attrs) do
    op = sanitize_op(op)
    left = attr_to_pos(schemas_attrs, tk, attr)
    {op, left, right}
  end

  def where_to_guard(%{op: op, attr: attr, tk: tk, arg_name: arg_name, right_type: :arg} = _clause, _data, args, schemas_attrs) do
    op = sanitize_op(op)
    left = attr_to_pos(schemas_attrs, tk, attr)
    right = Map.get(args, arg_name)
    {op, left, right}
  end

  def where_to_guard(%{op: op, attr: lattr, tk: tk, other_lvar: other_lvar, other_lvar_attr: rattr, right_type: :lvar} = _clause, data, _args, schemas_attrs) do
    left = attr_to_pos(schemas_attrs, tk, lattr)
    other_entities = Map.get(data, other_lvar)
    cond do
      is_nil(other_entities) -> :unmet_deps
      Enum.empty?(other_entities) -> :unmet_deps
      true ->
        right_values = Enum.map(other_entities, fn {_id, entity} ->
          Map.get(entity, rattr)
        end)
        guard_in(op, left, right_values)
    end
  end
  # }}}

  
  # {{{ get_entities(sorcery_module, tk, ids)
  # Given a tk and list of ids, returns all the matching entities, if possible. In their map form
  def get_entities(sorcery_module, tk, ids) do
    schemas = sorcery_module.config().schemas
    schemas_attrs = tk_attrs_map(schemas)

    :mnesia.transaction(fn -> 
      for id <- ids do
        :mnesia.read({tk, id})
      end
    end)
    |> case do
      {:atomic, li} ->
        entities = Enum.reduce(li, [], fn 
          [ent_tup], acc ->
            [tk | ent_list] = Tuple.to_list(ent_tup)
            ent = Enum.zip(schemas_attrs[tk], ent_list)
            |> Enum.into(%{})
            [ent | acc]
          [], acc -> acc
        end)
        {:ok, entities}
      err -> {:error, err}
    end
  end
  # }}}




end
