defmodule Sorcery.PortalServer.Commands.PortalMerge do
  @moduledoc false
  import Sorcery.Helpers.Maps

  def entry(%{portal: portal}, state) do
    %{parent_pid: parent_pid, portal_name: name} = portal

    state
    |> put_in_p([:sorcery, :portals_to_parent, parent_pid, name], portal)
  end


end
