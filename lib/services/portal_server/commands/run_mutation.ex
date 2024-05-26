defmodule Sorcery.PortalServer.Commands.RunMutation do
  @moduledoc false

  def entry(%{mutation: mutation} = msg, state) do

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
