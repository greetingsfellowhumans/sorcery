defmodule MyApp.Schemas.Team do
  use Sorcery.Schema, 
    meta: %{ optional?: false },
    fields: %{
      name: %{t: :string, min: 4, max: 45, default: "Nameless"},
      location_id: %{t: :fk, module: MyApp.Schemas.BattleArena},
    }
end
