defmodule Sorcery.PortalServer.PortalTest do
  use ExUnit.Case
  alias Sorcery.PortalServer.Portal, as: Portal
  doctest Portal
  import Sorcery.Setups

  setup [:spawn_portal]

  test "Portals", %{portal: portal} do
    frozen_portal = Portal.freeze(portal)
    assert portal.known_matches.data["?arena"] == frozen_portal.known_matches.data.battle_arena

    players = Map.merge(
      portal.known_matches.data["?player"],
      portal.known_matches.data["?all_players"]
    )
    assert portal.known_matches.data["?arena"] == frozen_portal.known_matches.data.battle_arena
    assert players == frozen_portal.known_matches.data.player
  end



end

