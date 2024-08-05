defmodule Sorcery.PortalServer.Commands.RunMutation do
  @moduledoc false
  import Sorcery.Helpers.Maps

  def entry(%{mutation: mutation} = msg, inner_state) do
    child_pid = mutation.portal.child_pid
    mutation = 
      mutation
      |> refresh_data(inner_state)
      |> apply_operations()
    msg = Map.put(msg, :mutation, mutation)

    # Submit changes to store
    case update_the_store(msg, inner_state) do
      {:ok, results} ->
        on_success(child_pid, msg, results)
        child_mutation = Sorcery.Mutation.ChildrenMutation.init(mutation, results)
        diff = Sorcery.Mutation.Diff.new(child_mutation)
        inner_state.config_module.run_mutation(results, diff)

      {:error, err} -> on_fail(child_pid, msg, err)
      err -> 
        dbg err
    end

    inner_state
  end

  # {{{ on_success
  def on_success(child_pid, original_msg, data) do
    args = Map.get(original_msg, :args, %{})
           |> Map.put(:data, data)
    msg = %{
      command: :mutation_success,
      mutation: original_msg.mutation, 
      args: args
    }

    send(child_pid, {:sorcery, msg})
  end
  # }}}

  # {{{ on_fail
  def on_fail(child_pid, original_msg, err) do
    args = Map.get(original_msg, :args, %{})
           |> Map.put(:error, err)
    msg = %{
      command: :mutation_failed,
      mutation: original_msg.mutation, 
      args: args
    }

    send(child_pid, {:sorcery, msg})
  end
  # }}}

  # To eliminate the possibility of race conditions and more nefarious issues
  # We grab the most recent data from SorceryDb
  # Don't worry about postgres, etc. having *more* up to date data, because:
  #   1. Mutations are based on a singular portal
  #   2. They are run by the same PortalServer that created the portal
  #   3. The PortalServer itself runs synchronously.
  #      Therefore, it would be the one updating said data. 
  #      And since it waits for SorceryDb to update before continuing
  #      We can logically prove that SorceryDb is technically up to date at this point in time.
  defp refresh_data(mutation, _inner_state) do
    tk_ids = Enum.reduce(mutation.operations, %{}, fn
      {:update, [tk, id | _], _}, acc -> update_in_p(acc, [tk], [id], &([id | &1]))
      {:put, [tk, id | _], _}, acc -> update_in_p(acc, [tk], [id], &([id | &1]))
    end)
    |> Enum.reduce(%{}, fn {tk, ids}, acc -> Map.put(acc, tk, Enum.uniq(ids)) end)
    data = Enum.reduce(tk_ids, %{}, fn {tk, ids}, acc ->
      case Sorcery.SorceryDb.Query.get_entities(Src, tk, ids) do
        {:ok, entities} ->
          Enum.reduce(entities, acc, fn %{id: id} = entity, acc ->
            put_in_p(acc, [tk, id], entity)
          end)
        err -> 
          raise "Unable to find the matching entities for :#{tk}"
      end
    end)
    
    mutation
    |> Map.put(:old_data, data)
    |> Map.put(:new_data, data)
  end

  defp apply_operations(mutation) do
    data = Enum.reduce(mutation.operations, mutation.new_data, fn 

      {:put, path, value}, new_data -> put_in_p(new_data, path, value)

      {:update, path, cb}, new_data ->
        old_entity = get_in_p(mutation.old_data, path)
        new_entity = get_in_p(new_data, path)
        new_entity = cb.(old_entity, new_entity)
        put_in_p(new_data, path, new_entity)

    end)
    Map.put(mutation, :new_data, data)
  end


  defp update_the_store(%{mutation: mutation}, inner_state) do
    mutation = Sorcery.Mutation.ParentMutation.init(mutation)
    adapter = inner_state.store_adapter
    Sorcery.StoreAdapter.mutation(adapter, inner_state, mutation)
  end

end
