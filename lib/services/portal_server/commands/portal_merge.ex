defmodule Sorcery.PortalServer.Commands.PortalMerge do
  @moduledoc false
  import Sorcery.Helpers.Maps

  def entry(%{portal: portal}, %Sorcery.PortalServer.InnerState{} = inner_state) do
    %{portal_name: name} = portal
    pending_portals = List.delete(inner_state.pending_portals, name)

    inner_state
    |> put_in_p([:portals, name], portal)
    |> put_in_p([:pending_portals], pending_portals)
  end


end
