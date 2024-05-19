defmodule Sorcery.PortalServer.Commands.ReplacePortal do
  @moduledoc false
  #alias Sorcery.StoreAdapter
  import Sorcery.Helpers.Maps


  def entry(%{args: %{parent: parent, portal_name: portal_name, data: data} } = msg, state) do
    "@TODO Also apply the finds here"

    state
    |> put_in_p([:sorcery, :portals_to_parent, parent, portal_name, :known_matches, :data], data)
  end

end
