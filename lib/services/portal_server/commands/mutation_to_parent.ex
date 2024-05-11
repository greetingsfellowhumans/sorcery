defmodule Sorcery.PortalServer.Commands.MutationToParent do
  @moduledoc false
  ######
  # When a child PS sends a mutation to a parent PS
  ######
  alias Sorcery.Mutation
  alias Mutation.Diff
  alias Sorcery.Query.ReverseQuery, as: RQ
  alias Sorcery.StoreAdapter
  alias Sorcery.PortalServer.Portal
  import Sorcery.Helpers.Maps


  def entry(%{args: %{mutation: mutation}, from: child_pid} = _msg, state) do
    mutation = Sorcery.Mutation.ParentMutation.init(mutation)
    adapter = state.sorcery.store_adapter
    case Sorcery.StoreAdapter.mutation(adapter, state, mutation) do
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

        state
        |> update_portals(pids, mutation)

      err ->
        dbg err
        state
    end
  end


  defp update_portals(state, pids, mutation) do
    Enum.reduce(pids, state, fn pid, state ->
      portals = state.sorcery.portals_to_child[pid]
      Enum.reduce(portals, state, fn {portal_name, portal}, state ->
        portal = Portal.handle_mutation(portal, mutation)
        put_in_p(state, [:sorcery, :portals_to_child, pid, portal_name], portal)
      end)
    end)
  end


end
