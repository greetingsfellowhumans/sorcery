defmodule Sorcery.PortalServer.Commands.PortalMerge do
  @moduledoc false
  import Sorcery.Helpers.Maps

  def entry(%{portal: portal}, state) do
    %{portal_name: name} = portal

    state
    |> put_in_p([:sorcery, :portals, name], portal)
  end


end
