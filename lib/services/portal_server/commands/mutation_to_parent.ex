defmodule Sorcery.PortalServer.Commands.MutationToParent do
  @moduledoc false
  ######
  # When a child PS sends a mutation to a parent PS
  ######
  alias Sorcery.Mutation
  alias Mutation.Diff
  alias Sorcery.Query.ReverseQuery, as: RQ


  def entry(%{args: %{mutation: mutation}, from: child_pid} = _msg, state) do
    mutation = Sorcery.Mutation.ParentMutation.init(mutation)
    case state.sorcery.store_adapter.run_mutation(state, mutation) do
      {:ok, data} ->
        mutation = Sorcery.Mutation.ChildrenMutation.init(mutation, data)
        diff = Sorcery.Mutation.Diff.new(mutation)
        pids = Enum.reduce(state.sorcery.portals_to_child, [], fn {pid, portals}, acc ->
          any? = Enum.any?(portals, fn {_, portal} ->
            RQ.diff_matches_portal?(diff, portal)
          end) 

          if any?, do: [pid | acc], else: acc
        end)
        for pid <- pids do
          msg = %{
            from: self(),
            command: :mutation_to_children,
            args: %{mutation: mutation}
          }
          send(pid, {:sorcery, msg})
        end

      _ -> :error
    end

    state
  end


end

