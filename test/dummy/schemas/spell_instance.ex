defmodule MyApp.Schemas.SpellInstance do
  use Sorcery.Schema, 
    fields: %{
      type_id: %{t: :fk, module: MyApp.Schemas.SpellType, optional?: false},
      player_id: %{t: :fk, module: MyApp.Schemas.Player, optional?: false},
    }
end
