defmodule Sorcery.PortalServer.Commands.ReceivePortal do
  import Sorcery.Helpers.Maps


  def entry(%{args: %{portal: portal, portal_name: portal_name}} = _msg, state) do
    state
    |> put_in_p([:sorcery, :portals_to_parent, portal_name], portal)
  end


end

