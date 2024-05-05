defmodule Sorcery.PortalServer.Commands.MutationToParent do
  @moduledoc false
  ######
  # When a child PS sends a mutation to a parent PS
  ######


  def entry(%{args: %{mutation: mutation}, from: child_pid} = _msg, state) do
    mutation = Sorcery.Mutation.ParentMutation.init(mutation)
    case state.sorcery.store_adapter.run_mutation(state, mutation) do
      {:ok, data} ->
        mutation = Sorcery.Mutation.ChildrenMutation.init(mutation, data)
        diff = Sorcery.Mutation.Diff.new(mutation)
        msg = %{
          from: self(),
          command: :mutation_to_children,
          args: %{mutation: mutation}
        }
        send(child_pid, {:sorcery, msg})

      _ -> :error
    end

    state
  end


end

