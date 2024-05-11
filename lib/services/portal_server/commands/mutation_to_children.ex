defmodule Sorcery.PortalServer.Commands.MutationToChildren do
  @moduledoc false
  alias Sorcery.PortalServer.Portal
  import Sorcery.Helpers.Maps


  def entry(%{from: parent, args: %{mutation: mutation}} = _msg, state) do
    state
    |> update_portals(parent, mutation)
  end


  defp update_portals(state, pid, mutation) do
    portals = state.sorcery.portals_to_parent[pid]
    Enum.reduce(portals, state, fn {portal_name, portal}, state ->
      portal = Portal.handle_mutation(portal, mutation)
      put_in_p(state, [:sorcery, :portals_to_parent, pid, portal_name], portal)
    end)
  end


end
