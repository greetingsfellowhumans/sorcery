defmodule Sorcery.Query.BasicReverseTest do
  use ExUnit.Case
  alias MyApp.Queries.{GetBattle}
  #alias Sorcery.Query.ReverseQuery, as: RQ
  alias Sorcery.ReturnedEntities, as: RE
  #alias Sorcery.Mutation.{Diff, DiffRow}


  test "Build the :find sets" do
    {:ok, pid} = GenServer.start_link(MyApp.PortalServers.Postgres, %{})
    msg = %{
      command: :spawn_portal,
      from: self(),
      args: %{player_id: 1, portal_name: :battle_portal},
      query: GetBattle,
    }
    send(pid, {:sorcery, msg})
    assert_receive {:sorcery, %{args: %{portal: portal}}}
    _results = portal.known_matches


    spell = RE.get_entities(portal.known_matches, "?spells") |> Enum.at(5)
    assert is_integer(spell.id)
    assert is_integer(spell.player_id)
    assert is_integer(spell.type_id)


    #diff_row = DiffRow.new(%{tk: :spell_instance, old_entity: spell, changes: %{player_id: 9_999_999}})
    #diff = Diff.new([diff_row])
    #assert RQ.diff_matches_portal?(diff, portal)

    #wrong_spell = %{id: 999999, player_id: 9_999_998, type_id: 1}
    #refute wrong_spell in RE.get_entities( results, "?spells")

    #diff_row = DiffRow.new(%{tk: :spell_instance, old_entity: wrong_spell, changes: %{player_id: 9_999_999}})
    #diff = Diff.new([diff_row])
    #refute RQ.diff_matches_portal?(diff, portal)

  
    ## Rev queries must match ALL clauses
    #team = RE.get_entities(portal.known_matches, "?all_teams") |> Enum.random()
    #new_player =  %{id: 99999999, team_id: team.id, health: 100}
    #dead_player = %{id: 99999990, team_id: team.id, health: -100}

    #diff_row = DiffRow.new(%{tk: :player, new_entity: new_player})
    #diff = Diff.new([diff_row])
    #assert RQ.diff_matches_portal?(diff, portal)

    #diff_row = DiffRow.new(%{tk: :player, new_entity: dead_player})
    #diff = Diff.new([diff_row])
    #refute RQ.diff_matches_portal?(diff, portal)
  end


end
