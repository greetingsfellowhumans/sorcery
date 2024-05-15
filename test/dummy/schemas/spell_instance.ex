defmodule MyApp.Sorcery.Schemas.SpellInstance do
  use Sorcery.Schema, 
    meta: %{ optional?: false },
    fields: %{
      type_id: %{t: :fk, module: MyApp.Sorcery.Schemas.SpellType},
      player_id: %{t: :fk, module: MyApp.Sorcery.Schemas.Player},
    }
end
