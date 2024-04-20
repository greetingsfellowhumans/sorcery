defmodule MyApp.Schemas.SpellInstance do
  use Sorcery.Schema, 
    meta: %{ optional?: false },
    fields: %{
      type_id: %{t: :fk, module: MyApp.Schemas.SpellType},
      player_id: %{t: :fk, module: MyApp.Schemas.Player},
    }
end
