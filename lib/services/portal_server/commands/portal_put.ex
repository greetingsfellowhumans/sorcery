defmodule Sorcery.PortalServer.Commands.PortalPut do
  @moduledoc false
  import Sorcery.Helpers.Maps

  ################
  # This is just like PortalMerge, except it only replaces PART of the portal.
  ################

  def entry(%{data: data, portal_name: portal_name, updated_at: updated_at}, state) do
    state
    |> put_in_p([:sorcery, :portals, portal_name, :known_matches, :data], data)
    |> put_in_p([:sorcery, :portals, portal_name, :updated_at], updated_at)
  end


end
