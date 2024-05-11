defmodule Sorcery.PortalServer.Commands.SpawnPortal do
  @moduledoc false
  alias Sorcery.PortalServer.Portal
  alias Sorcery.Query.ReverseQuery, as: RQ
  import Sorcery.Helpers.Maps
  alias Sorcery.StoreAdapter


  def entry(%{query: module, from: from} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    args = msg[:args] || %{}
    clauses = module.clauses(args)


    fwd_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :forward)
    rev_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :reverse)
    finds = RQ.generate_find([fwd_find_set, rev_find_set])

    case StoreAdapter.query(store_adapter, state.sorcery, clauses, finds) do
      {:ok, results} ->
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

        parent_portal =
          portal
          |> Map.put(:known_matches, results)
          |> Map.put(:rev_find_set, rev_find_set)
        msg = %{
          command: :spawn_portal_response,
          from: self(),
          args: Map.merge(args, %{portal: child_portal})
        }
        send(from, {:sorcery, msg})

        state
        |> put_in_p([:sorcery, :portals_to_child, from, args.portal_name], parent_portal)
    end

  end


end
