defmodule Sorcery.PortalServer.Commands.RunMutation do
  @moduledoc false
  alias Sorcery.SorceryDb, as: SDB
  alias Sorcery.SorceryDb.ReverseQuery, as: RQ

  def entry(%{mutation: mutation, portal: portal} = msg, state) do
    %{child_pid: pid, args: args, query_module: query_module, portal_name: portal_name} = portal
    dbg "PING! Run Mutation"

    # Submit changes to store
    case update_the_store(msg, state) do
      {:ok, results} ->
        child_mutation = Sorcery.Mutation.ChildrenMutation.init(mutation, results)
        diff = Sorcery.Mutation.Diff.new(child_mutation)

        state.sorcery.config_module.run_mutation(results, diff)

      err -> dbg err
    end


    state
  end


  defp update_the_store(%{mutation: mutation}, state) do
    mutation = Sorcery.Mutation.ParentMutation.init(mutation)
    adapter = state.sorcery.store_adapter
    Sorcery.StoreAdapter.mutation(adapter, state, mutation)
  end

end
