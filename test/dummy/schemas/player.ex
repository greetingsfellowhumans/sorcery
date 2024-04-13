defmodule MyApp.Schemas.Player do
  use Sorcery.Schema, 
    fields: %{
      name: %{t: :string, min: 0, max: 45, default: "Nameless"},
      age: %{t: :integer, min: 0, max: 99, optional?: false},
      arena_id: %{t: :fk, module: MyApp.Schemas.BattleArena, optional?: false},
    }
end
