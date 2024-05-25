defmodule Sorcery.PortalServer.Commands.PortalPut do
  @moduledoc false
  import Sorcery.Helpers.Maps

  ################
  # This is just like PortalMerge, except it only replaces PART of the portal.
  ################

  def entry(%{data: data, portal_name: portal_name, updated_at: updated_at}, state) do
    parent_pid = Enum.find_value(state.sorcery.portals_to_parent, fn {pid, portals} ->
      names = Map.keys(portals)
      if portal_name in names, do: pid, else: nil
    end)

    state
    |> put_in_p([:sorcery, :portals_to_parent, parent_pid, portal_name, :known_matches, :data], data)
    |> put_in_p([:sorcery, :portals_to_parent, parent_pid, portal_name, :updated_at], updated_at)
  end


end
