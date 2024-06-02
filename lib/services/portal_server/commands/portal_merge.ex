defmodule Sorcery.PortalServer.Commands.PortalMerge do
  @moduledoc false
  import Sorcery.Helpers.Maps

  def entry(%{portal: portal}, %Sorcery.PortalServer.InnerState{} = inner_state) do
    %{portal_name: name} = portal

    inner_state
    |> put_in_p([:portals, name], portal)
  end


end
