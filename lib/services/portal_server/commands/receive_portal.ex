defmodule Sorcery.PortalServer.Commands.ReceivePortal do
  alias Sorcery.PortalServer.Portal
  alias Sorcery.Query.ReverseQuery, as: RQ
  alias Sorcery.ReturnedEntities, as: RE
  import Sorcery.Helpers.Maps


  def entry(%{args: %{portal: portal, portal_name: portal_name}} = msg, state) do
    state
    |> put_in_p([:sorcery, :portals_to_parent, portal_name], portal)
  end


end

