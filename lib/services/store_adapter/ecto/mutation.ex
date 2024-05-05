defmodule Sorcery.StoreAdapter.Ecto.Mutation do
  @moduledoc false
  alias Ecto.Multi, as: M
  import Sorcery.Helpers.Maps


  def run_mutation(portal_server_state, mutation) do
    repo = portal_server_state.sorcery.args.repo_module
    schemas = portal_server_state.sorcery.config_module.config().schemas
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
    Enum.reduce(mutation.inserts, multi, fn {tk, table}, acc ->
      mod = schemas[tk]

      Enum.reduce(table, acc, fn {id, new_entity}, acc ->
        cs = mod.sorcery_insert_cs(new_entity)
        M.insert(acc, "insert:#{tk}:#{id}", cs)
      end)

    end)
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
