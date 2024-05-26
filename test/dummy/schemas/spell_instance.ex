defmodule Src.Schemas.SpellInstance do
  use Sorcery.Schema, 
    meta: %{ optional?: false },
    fields: %{
      type_id: %{t: :fk, module: Src.Schemas.SpellType},
      player_id: %{t: :fk, module: Src.Schemas.Player},
    }
end
