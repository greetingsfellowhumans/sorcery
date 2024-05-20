defmodule Sorcery.PortalServer.Commands.SpawnPortal do
  @moduledoc false
  alias Sorcery.PortalServer.Portal
  alias Sorcery.Query.ReverseQuery, as: RQ
  import Sorcery.Helpers.Maps
  alias Sorcery.StoreAdapter


  defp sdb_mutation(%{data: data, lvar_tks: lvar_tks}) do
    updates = Enum.reduce(data, %{}, fn {lvar, lvar_data}, acc ->
      tk = lvar_tks[lvar]
      Map.update(acc, tk, lvar_data, &(Map.merge(&1, lvar_data)))
    end)
    %{inserts: %{}, deletes: %{}, updates: updates}
  end

  def entry(%{query: module, from: from, args: args} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    args = msg[:args] || %{}
    clauses = module.clauses(args)


    fwd_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :forward)
    rev_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :reverse)
    finds = RQ.generate_find([fwd_find_set, rev_find_set])

    case StoreAdapter.query(store_adapter, state.sorcery, clauses, finds) do
      {:ok, results} ->
        timestamp = Time.utc_now()

        # Send results to SorceryDb
        pid_portals = [%{pid: from, query_module: module, args: args, portal_name: args.portal_name}]
        mutation = sdb_mutation(results)
        state.sorcery.config_module.run_mutation(mutation, pid_portals, self())

        portal = Portal.new(%{
          query_module: module,
          child_pids: [from],
          parent_pid: self(), 
          args: args,
        })
        child_portal =
          portal
          |> Map.put(:known_matches, results)
          |> Map.put(:fwd_find_set, fwd_find_set)
          |> Map.put(:updated_at, timestamp)

        parent_portal =
          portal
          |> Map.put(:known_matches, results)
          |> Map.put(:rev_find_set, rev_find_set)
          |> Map.put(:updated_at, timestamp)

        msg = %{
          command: :spawn_portal_response,
          from: self(),
          args: Map.merge(args, %{portal: child_portal})
        }
        send(from, {:sorcery, msg})


        #######################################
        # Now build the watcher rows
        # How do you even design this!?!?
        # Because I can simply map the ids of all the entities...
        # But I really need to also have rows based on queries.
        # What if the trick is ALSO to store pairs of QueryModules, and arg maps...
        # Then when a diff comes in... then what?
        # Then for both the before and after, we check:
        #   could the entity fit into any of the LVARs?
        #   And when we have complex lvars, we can use the stored ones
        # For example, look at get_battle
        # Suppose a team joins the location_id
        # So we check ?team, does the :id match ?player.id?
        # We check the ets tables matching ?player, get list of entities, map to :id, and FALSE
        # ok now move down to ?all_teams. It needs location_id to == ?arena.id
        # Again, grab the ?arena from ets. Is the diff.team.location_id in ?arena.ids? TRUE
        # So it matches.
        #
        # The algorithm
        # From ets, get every query_module. Remove duplicates
        # now get the set of all portals using that query_module
        # For portal <-portals do
        #
        #   for lvar <- lvars, where tk == lvar.tk  do
        # too tired to continue. sorry

  

        #rev_entities = RQ.get_known_matches(results, rev_find_set)
        RQ.parse_known_for_ets(parent_portal)
        #|> dbg()

        #######################################

        state
        |> put_in_p([:sorcery, :portals_to_child, from, args.portal_name], parent_portal)
    end

  end


end
