defmodule Sorcery.PortalServer.Commands.ReceivePortal do
  @moduledoc false
  import Sorcery.Helpers.Maps


  def entry(%{from: parent, args: %{portal: portal, portal_name: portal_name}} = _msg, state) do
    state
    |> put_in_p([:sorcery, :portals_to_parent, parent, portal_name], portal)
  end


end

