defmodule Sorcery.SorceryDbTest do
  use ExUnit.Case
  alias Sorcery.Mutation, as: M
  import Sorcery.Setups

  setup [:spawn_portal, :teams_portal]

  test "SorceryDb can be populated via mutations", %{portal: portal} do
    m = M.init(portal)
        |> M.create_entity(:team, "?my_team", %{name: "Hello!", id: 953, location_id: 953})
    data = %{
      updates: %{},
      inserts: %{team: %{953 => %{id: 953, name: "Hello!", location_id: 953}}},
      deletes: %{}
    }

    m = Sorcery.Mutation.ChildrenMutation.init(m, data)
    MyApp.Sorcery.run_mutation(m, [self()])
    assert_receive {:sorcery, %{command: :rerun_queries}}
  end


end
