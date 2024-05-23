defmodule Sorcery.PortalServer.Commands.PortalPut do
  @moduledoc false
  import Sorcery.Helpers.Maps

  ################
  # This is just like PortalMerge, except it only replaces PART of the portal.
  ################

  #def entry(%{portal_name: name, parent_pid: parent_pid, portal: portal}, state) do
  def entry(%{data: data, portal_name: portal_name, updated_at: updated_at}, state) do
    dbg "Ping! PortalPut"
    parent_pid = Enum.find_value(state.sorcery.portals_to_parent, fn {pid, portals} ->
      names = Map.keys(portals)
      if portal_name in names, do: pid, else: nil
    end)

    #dbg data

    #dbg "BEFORE"
    #state
    #|> get_in_p([:sorcery, :portals_to_parent, parent_pid, portal_name, :known_matches, :data, "?all_players", 7])
    #|> dbg()

    #dbg "AFTER"
    #get_in_p(data, ["?all_players", 7])
    #|> dbg()

    #dbg parent_pid
    #dbg portal_name

    state
    |> put_in_p([:sorcery, :portals_to_parent, parent_pid, portal_name, :known_matches, :data], data)
    |> put_in_p([:sorcery, :portals_to_parent, parent_pid, portal_name, :updated_at], updated_at)
  end


end
