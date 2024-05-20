defmodule Sorcery.PortalServer.Commands.MutationToParent do
  @moduledoc false
  ######
  # When a child PS sends a mutation to a parent PS
  ######
  #alias Sorcery.Mutation
  #alias Mutation.Diff
  alias Sorcery.Query.ReverseQuery, as: RQ
  #alias Sorcery.StoreAdapter
  alias Sorcery.PortalServer.Portal
  import Sorcery.Helpers.Maps


  def entry(%{args: %{mutation: mutation}, from: _child_pid} = _msg, state) do
    mutation = Sorcery.Mutation.ParentMutation.init(mutation)
    adapter = state.sorcery.store_adapter
    case Sorcery.StoreAdapter.mutation(adapter, state, mutation) do
      {:ok, data} ->
        mutation = Sorcery.Mutation.ChildrenMutation.init(mutation, data)
        diff = Sorcery.Mutation.Diff.new(mutation)

        ##########################################
        # Possibly removing these
        #pids = get_watching_pids(state, diff)
        #inform_children(pids, mutation)
        ##########################################

        pid_portals = get_watching_pid_portals(state, diff)
        state.sorcery.config_module.run_mutation(mutation, pid_portals, self())
        pids = Enum.map(pid_portals, &(&1.pid))


        state
        |> update_portals(pids, mutation)

      err ->
        dbg err
        state
    end
  end


  # {{{ inform_children(pids, mutation)
  defp inform_children(pids, mutation) do
    for pid <- pids do
      msg = %{
        from: self(),
        command: :mutation_to_children,
        args: %{mutation: mutation}
      }
      #send(pid, {:sorcery, msg})
    end
  end
  # }}}


  # {{{ get_watching_pids(state, diff)
  defp get_watching_pids(state, diff) do
    Enum.reduce(state.sorcery.portals_to_child, [], fn {pid, portals}, acc ->
      any? = Enum.any?(portals, fn {_, portal} ->
        RQ.diff_matches_portal?(diff, portal)
      end)
      if any?, do: [pid | acc], else: acc
    end)
  end
  # }}}


  # {{{ get_watching_pid_portals(state, diff)
  defp get_watching_pid_portals(state, diff) do
    Enum.reduce(state.sorcery.portals_to_child, [], fn {pid, portals}, acc ->
      Enum.reduce(portals, acc, fn {portal_name, portal}, matching_portals ->
        if RQ.diff_matches_portal?(diff, portal) do
          body = Map.take(portal, [:args, :query_module])
                 |> Map.put(:pid, pid)
                 |> Map.put(:portal_name, portal_name)
          [body | matching_portals]
        else
          matching_portals
        end
      end)
    end)
  end
  # }}}


  # {{{ update_portals(state, pids, mutation)
  defp update_portals(state, pids, mutation) do
    Enum.reduce(pids, state, fn pid, state ->
      portals = state.sorcery.portals_to_child[pid]
      Enum.reduce(portals, state, fn {portal_name, portal}, state ->
        new_portal = Portal.handle_mutation(portal, mutation)
        put_in_p(state, [:sorcery, :portals_to_child, pid, portal_name], new_portal)
      end)
    end)
  end
  # }}}


end
