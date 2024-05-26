if Mix.env() == :test do
  alias Src.Schemas.{Player, BattleArena, Team, SpellType, SpellInstance}
  alias Sorcery.Repo

  arena_names = ["Ice Room", "Candy Land", "Fire Pit"]
  spells = [
    %{name: "Heal", power: -10, cost: 25},
    %{name: "Fireball", power: 40, cost: 85},
    %{name: "Pew Pew", power: 15, cost: 10},
  ]
  for spell <- spells do
    Repo.insert!(SpellType.gen_cs(spell))
  end

  for name <- arena_names do
    arena = Repo.insert!(BattleArena.gen_cs(%{name: name}))

    # 5 teams are in each arena
    for _n <- 1..5 do
      team = Repo.insert!(Team.gen_cs(%{location_id: arena.id}))

      # 4 players on each team
      for _n <- 1..4 do
        Repo.insert!(Player.gen_cs(%{team_id: team.id}))
      end
    end
  end

  all_spells = Repo.all(SpellType)
  all_players = Repo.all(Player)
  for spell <- all_spells, player <- all_players do
    Repo.insert!(SpellInstance.gen_cs(%{type_id: spell.id, player_id: player.id}))
  end

end
