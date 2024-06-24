defmodule Sorcery.StoreAdapter.Ecto.Mutation do
  @moduledoc false
  alias Ecto.Multi, as: M
  import Sorcery.Helpers.Maps


  def run_mutation(inner_state, mutation) do
    repo = inner_state.args.repo_module
    schemas = inner_state.config_module.config().schemas
    M.new()
    |> handle_updates(mutation, schemas)
    |> handle_inserts(mutation, schemas)
    |> handle_deletes(mutation, schemas)
    |> repo.transaction()
    |> handle_formatting()
  end

  defp handle_formatting({:ok, resp}) do
    default = %{updates: %{}, inserts: %{}, deletes: %{}}
    m = Enum.reduce(resp, default, fn {transaction_id, entity_struct}, acc ->
      entity = Map.from_struct(entity_struct)
               |> Map.delete(:__meta__)

      case String.split(transaction_id, ":") do
        ["insert", tk_str, _lvar] ->
          tk = String.to_existing_atom(tk_str)
          id = entity_struct.id
          put_in_p(acc, [:inserts, tk, id], entity)

        ["update", tk_str, _id_str] ->
          tk = String.to_existing_atom(tk_str)
          id = entity_struct.id
          put_in_p(acc, [:updates, tk, id], entity)

        ["delete", tk_str, id_str] -> 
          tk = String.to_existing_atom(tk_str)
          id = String.to_integer(id_str)
          update_in_p(acc, [:deletes, tk], [id], fn ids -> [id | ids] end)
      end
    end)
     
    {:ok, m}
  end



  # {{{ handle_updates
  defp handle_updates(multi, mutation, schemas) do
    Enum.reduce(mutation.updates, multi, fn {tk, table}, acc ->
      mod = schemas[tk]

      Enum.reduce(table, acc, fn {id, new_entity}, acc ->
        original_entity = mutation.old_data[tk][id]
        original_entity = struct(mod, original_entity)
        cs = mod.sorcery_update_cs(original_entity, new_entity)
        M.update(acc, "update:#{tk}:#{id}", cs)
      end)

    end)
  end
  # }}}


  # {{{ handle_inserts
  defp handle_inserts(multi, mutation, schemas) do
    order = insert_order(mutation.inserts)
    Enum.reduce(order, multi, fn {tk, lvar}, acc ->
      mod = schemas[tk]
      entity = get_in_p(mutation, [:inserts, tk, lvar])
      id = entity.id
      M.insert(acc, "insert:#{tk}:#{id}", fn m ->
        entity = just_in_time_insertion_cleanup(m, entity, order)
        mod.sorcery_insert_cs(entity)
      end)
    end)
  end

  defp just_in_time_insertion_cleanup(multi, entity, order) when is_struct(entity) do
    just_in_time_insertion_cleanup(multi, Map.from_struct(entity), order)
  end
  defp just_in_time_insertion_cleanup(multi, entity, order) do
    Enum.reduce(entity, entity, fn 
      {:id, _}, acc -> acc
      {entity_attr, "?" <> _ = full_lvar}, acc ->
        {lvar, attr} = String.split(full_lvar, ".")
                       |> case do
                         [lvar, attr] -> {lvar, String.to_existing_atom(attr)}
                         [lvar] -> {lvar, :id}
                       end
        tk = Enum.find_value(order, fn {tk, l} -> if l == lvar, do: tk, else: nil end)
        multi_k = "insert:#{tk}:#{lvar}"
        new_v = get_in_p(multi, [multi_k, attr])
        Map.put(acc, entity_attr, new_v)
      _, acc -> acc
    end)
  end


  @doc false
  def insert_order(inserts) do
    tups = Enum.reduce(inserts, [], fn {tk, table}, acc ->
      lvars = Map.keys(table)
      tk_tups = Enum.map(lvars, &{tk, &1})
      [tk_tups | acc]
    end) |> List.flatten()
    insert_order(inserts, tups, [])
  end
  def insert_order(_inserts, [], ordered), do: ordered |> Enum.reverse()
  def insert_order(inserts, [{tk, lvar} | tups], ordered) do
    entity = get_in_p(inserts, [tk, lvar])
    fields = entity |> Map.delete(:id) |> Map.values()
    Enum.all?(fields, fn 
      "?" <> _ = dep -> 
        [dep | _] = String.split(dep, ".")
        !Enum.any?(tups, fn {_, lvar} -> dep == lvar end)
      _ -> true
    end)
    |> if do
      insert_order(inserts, tups, [{tk, lvar} | ordered])
    else
      insert_order(inserts, tups ++ [{tk, lvar}], ordered)
    end
  end
  # }}}


  # {{{ handle_deletes
  defp handle_deletes(multi, mutation, schemas) do
    Enum.reduce(mutation.deletes, multi, fn {tk, ids}, acc ->
      Enum.reduce(ids, acc, fn id, acc ->
        M.delete(acc, "delete:#{tk}:#{id}", struct(schemas[tk], %{id: id}))
      end)
    end)
  end
  # }}}


end
