defmodule Sorcery.PortalServer.PortalQueryTest do
  use ExUnit.Case
  alias Sorcery.PortalServer.{Portal}
  alias Sorcery.Mutation, as: M
  alias M.{ParentMutation, ChildrenMutation}
  import Sorcery.Setups

  setup [:spawn_portal]

  test "Portal Query namechange", %{portal: portal, parent_pid: _parent} do
    mutation_data = %{
      inserts: %{
        spell_type: %{42 => %{id: 42, name: "Magic sparkles"}}, 
        spell_instance: %{1 => %{id: 100, type_id: 42, player_id: 1}}
      },
      updates: %{team: %{1 => %{id: 1, name: "My name has changed", location_id: 1}}},
      deletes: %{team: [2]},
    }
    m = M.init(portal)
        |> ParentMutation.init()
        |> ChildrenMutation.init(mutation_data)

    new_portal = Portal.handle_mutation(portal, m)
    assert new_portal.known_matches.data["?all_teams"][1].name == "My name has changed"
    assert new_portal.known_matches.data["?spell_types"][42].name == "Magic sparkles"

    assert Map.has_key?(portal.known_matches.data["?all_teams"], 2)
    refute Map.has_key?(new_portal.known_matches.data["?all_teams"], 2)
  end


end
