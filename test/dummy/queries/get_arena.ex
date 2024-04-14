defmodule MyApp.Queries.GetArena do
  use Sorcery.Query, %{
    find: %{"?arena" => :*, "?team" => [:name, :location_id]},
    args: %{
      arena_id: :integer
    },
    where: [
      [ "?arena", :battle_arena, [
        {:id, :args_arena_id},
        {:name, {:!=, "Private Arena"}},
      ]],
      [ "?team", :team, [
        {:location_id, "?arena.id"}
      ]]
    ]
  }

end
